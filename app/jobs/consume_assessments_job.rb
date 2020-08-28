# frozen_string_literal: true

require 'redis'

# ConsumeAssessmentsJob: Pulls assessments created in the split instance and saves them
class ConsumeAssessmentsJob < ApplicationJob
  queue_as :default

  def perform
    connection = Redis.new
    connection.subscribe 'reports' do |on|
      on.message do |_channel, msg|
        # message = SaraSchema::Validator.validate(:assessment, JSON.parse(msg))
        message = JSON.parse(msg)&.slice('threshold_condition_hash', 'reported_symptoms_array',
                                         'patient_submission_token', 'experiencing_symptoms', 'response_status')

        next if message.nil?

        patient = Patient.find_by(submission_token: message['patient_submission_token'])
        next if patient.nil?

        # Prevent duplicate patient assessment spam
        unless patient.latest_assessment.nil? # Only check for latest assessment if there is one
          next if patient.latest_assessment.created_at > ADMIN_OPTIONS['reporting_limit'].minutes.ago
        end

        # Get list of dependents excluding the patient itself.
        dependents = patient.dependents_exclude_self

        case message['response_status']
        when 'no_answer_voice'
          # If nobody answered, nil out the last_reminder_sent field so the system will try calling again
          patient.update(last_assessment_reminder_sent: nil)
          History.contact_attempt(patient: patient, comment: "Sara Alert called this monitoree's primary telephone \
                                                              number #{patient.primary_telephone} and nobody answered the phone.")
          unless dependents.blank?
            create_contact_attempt_history_for_dependents(dependents, "Sara Alert called this monitoree's head \
                                                                              of household and nobody answered the phone.")
          end

          next
        when 'no_answer_sms'
          # No need to wipe out last_assessment_reminder_sent so that another sms will be sent because the sms studio flow is kept open for 18hrs
          History.contact_attempt(patient: patient, comment: "Sara Alert texted this monitoree's primary telephone \
                                                             number #{patient.primary_telephone} during their preferred \
                                                             contact time, but did not receive a response.")
          unless dependents.blank?
            create_contact_attempt_history_for_dependents(dependents, "Sara Alert texted this monitoree's head of \
                                                                              household and did not receive a response.")
          end

          next
        when 'error_voice'
          # If there was an error in completeing the call, nil out the last_reminder_sent field so the system will try calling again
          patient.update(last_assessment_reminder_sent: nil)
          History.contact_attempt(patient: patient, comment: "Sara Alert was unable to complete a call to this \
                                                              monitoree's primary telephone number #{patient.primary_telephone}.")
          unless dependents.blank?
            create_contact_attempt_history_for_dependents(dependents, "Sara Alert was unable to complete a call \
                                                                              to this monitoree's head of household.")
          end

          next
        when 'error_sms'
          # If there was an error sending an SMS, nil out the last_reminder_sent field so the system will try calling again
          patient.update(last_assessment_reminder_sent: nil)
          History.contact_attempt(patient: patient, comment: "Sara Alert was unable to send an SMS to this monitoree's \
                                                             primary telephone number #{patient.primary_telephone}.")
          unless dependents.blank?
            create_contact_attempt_history_for_dependents(dependents, "Sara Alert was unable to send an SMS to \
                                                                              this monitoree's head of household.")
          end

          next
        end

        threshold_condition = ThresholdCondition.where(threshold_condition_hash: message['threshold_condition_hash']).first
        next unless threshold_condition

        if message['reported_symptoms_array']
          typed_reported_symptoms = Condition.build_symptoms(message['reported_symptoms_array'])
          reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: message['threshold_condition_hash'])
          assessment = Assessment.new(reported_condition: reported_condition, patient: patient, who_reported: 'Monitoree')
          assessment.symptomatic = assessment.symptomatic? || message['experiencing_symptoms']
          assessment.save
        else
          # If message['reported_symptoms_array'] is not populated then this assessment came in through
          # a generic channel ie: SMS where monitorees are asked YES/NO if they are experiencing symptoms
          patient.active_dependents.uniq.each do |pat|
            typed_reported_symptoms = if message['experiencing_symptoms']
                                        # Remove values so that the values will appear as blank in a symptomatic report
                                        # this will indicate that the person needs to be reached out to to get the actual values
                                        threshold_condition.clone_symptoms_remove_values
                                      else
                                        # The person is not experiencing symptoms, we can infer that the bool symptoms are the opposite
                                        # of the threshold values that represent symptomatic
                                        threshold_condition.clone_symptoms_negate_bool_values
                                      end
            reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: message['threshold_condition_hash'])
            assessment = Assessment.new(reported_condition: reported_condition, patient: pat)
            assessment.symptomatic = assessment.symptomatic? || message['experiencing_symptoms']
            # If current user in the collection of patient + patient dependents is the patient, then that means
            # that they reported for themselves, else we are creating an assessment for the dependent and
            # that means that it was the proxy who reported for them
            assessment.who_reported = if message['patient_submission_token'] == pat.submission_token
                                        'Monitoree'
                                      else
                                        'Proxy'
                                      end
            assessment.save
          end
        end
      rescue JSON::ParserError
        next
      end
    end
  rescue Redis::ConnectionError, Redis::CannotConnectError => e
    puts "ConsumeAssessmentsJob: Redis::ConnectionError (#{e}), retrying..."
    sleep(1)
    retry
  end

  private

  # Use the import method here to generate less SQL statements for a bulk insert of
  # dependent histories instead of 1 statement per dependent.
  def create_contact_attempt_history_for_dependents(dependents, comment)
    histories = []
    dependents.each do |dependent|
      histories << History.new(patient: dependent,
                               created_by: 'Sara Alert System',
                               comment: comment,
                               history_type: 'Contact Attempt')
    end
    History.import! histories
  end
end
