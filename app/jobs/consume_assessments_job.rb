# frozen_string_literal: true

require 'redis'
require 'redis-queue'

# ConsumeAssessmentsJob: Pulls assessments created in the split instance and saves them
class ConsumeAssessmentsJob < ApplicationJob
  queue_as :default

  def perform
    queue = Redis::Queue.new('q_bridge', 'bp_q_bridge', redis: Rails.application.config.redis)

    while (msg = queue.pop)
      begin
        message = JSON.parse(msg)&.slice('threshold_condition_hash', 'reported_symptoms_array',
                                         'patient_submission_token', 'experiencing_symptoms', 'response_status')

        # Invalid message
        if message.nil?
          Rails.logger.info 'ConsumeAssessmentsJob: skipping nil message...'
          queue.commit
          next
        end

        if !message['response_status'].in? ['opt_out', 'opt_out']
          patient = Patient.where(purged: false).find_by(submission_token: message['patient_submission_token'])
        end

        # When an opt_in or opt_out response_status is posted to us the patient_submission_token value is popuated with
        # a flow execution id, this is because a monitoree may send STOP/START outside the context of an assessment and
        # therefore the patient.submission_token will not be available. We get the responder associated with the opt_in
        # or opt_out phone number by requesting the phone number who sent the message in the associated flow execution id
        patient = if message['response_status'].in? %w[opt_out opt_in]
          phone_numbers = TwilioSender.get_phone_numbers_from_flow_execution(message['patient_submission_token'])
          monitoree_number = phone_numbers[:monitoree_number]
          sara_number = phone_numbers[:sara_number]
          # Handle BlockedNumber manipulation here in case no monitorees are associated with this number
          BlockedNumber.create(phone_number: monitoree_number) if message['response_status'] == 'opt_out'
          BlockedNumber.where(phone_number: monitoree_number).destroy_all if message['response_status'] == 'opt_in'
          Patient.responder_for_number(monitoree_number)&.first
        elsif patient.nil?
          # Perform patient lookup for old submission tokens
          patient_lookup = PatientLookup.find_by(old_submission_token: message['patient_submission_token'])
          Patient.find_by(submission_token: patient_lookup[:new_submission_token]) unless patient_lookup.nil?
        end

        # Failed to find patient
        if patient.nil?
          Rails.logger.info "ConsumeAssessmentsJob: skipping nil patient (token: #{message['patient_submission_token']})..."
          queue.commit
          next
        end

        # Prevent duplicate patient assessment spam
        # Only check for latest assessment if there is one
        if !patient.latest_assessment.nil? && (patient.latest_assessment.created_at > ADMIN_OPTIONS['reporting_limit'].minutes.ago)
          Rails.logger.info "ConsumeAssessmentsJob: skipping duplicate assessment (patient: #{patient.id})..."
          queue.commit
          next
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

          queue.commit
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

          queue.commit
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

          queue.commit
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

          queue.commit
          next
        when 'opt_out'
          # In cases of opt_in/opt_out the sara_number should always be available
          sara_number ||= '<Number Unavailable>'
          History.contact_attempt(patient: patient, comment: "Monitoree blocked SMS communications with Sara Alert by sending a\
                                                             STOP keyword via primary telephone number #{patient.primary_telephone} to\
                                                             the Sara Alert number #{sara_number}.")
          unless dependents.blank?
            create_contact_attempt_history_for_dependents(dependents, "Monitoree's head of household blocked SMS communications with Sara Alert by sending a\
                                                                      STOP keyword via primary telephone number #{patient.primary_telephone} to\
                                                                      the Sara Alert number #{sara_number}.")
          end
          queue.commit
          next
        when 'opt_in'
          # In cases of opt_in/opt_out the sara_number should always be available
          sara_number ||= '<Number Unavailable>'
          History.contact_attempt(patient: patient, comment: "Monitoree unblocked SMS communications with Sara Alert by sending a\
                                                             START keyword via primary telephone number #{patient.primary_telephone} to\
                                                             the Sara Alert number #{sara_number}.")
          unless dependents.blank?
            create_contact_attempt_history_for_dependents(dependents, "Monitoree's head of household unblocked SMS communications with Sara Alert by sending a\
                                                                      START keyword via primary telephone number #{patient.primary_telephone} to\
                                                                      the Sara Alert number #{sara_number}.")
          end
          queue.commit
          next
        when 'max_retries_sms'
          # Maximum amount of SMS response retries reached
          # nil out the last_reminder_sent field so the system will try sending another SMS assessment
          patient.update(last_assessment_reminder_sent: nil)
          History.contact_attempt(patient: patient, comment: "Monitoree exceeded the maximum number of assessment SMS response retries via\
                                                             primary telephone number #{patient.primary_telephone}.")
          unless dependents.blank?
            create_contact_attempt_history_for_dependents(dependents, "Monitoree's head of household exceeded the maximum number of assessment SMS response\
                                                                      rertries via primary telephone number #{patient.primary_telephone}.")
          end
          queue.commit
          next
        when 'max_retries_voice'
          # Maximum amount of voice response retries reached
          # nil out the last_reminder_sent field so the system will try sending another voice assessment
          patient.update(last_assessment_reminder_sent: nil)
          History.contact_attempt(patient: patient, comment: "Monitoree exceeded the maximum number of assessment voice response retries via\
                                                             primary telephone number #{patient.primary_telephone}.")
          unless dependents.blank?
            create_contact_attempt_history_for_dependents(dependents, "Monitoree's head of household exceeded the maximum number of assessment voice response\
                                                                      retries via primary telephone number #{patient.primary_telephone}.")
          end
          queue.commit
          next
        end

        if message['reported_symptoms_array']
          typed_reported_symptoms = Condition.build_symptoms(message['reported_symptoms_array'])
          reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: message['threshold_condition_hash'])
          assessment = Assessment.new(reported_condition: reported_condition, patient: patient, who_reported: 'Monitoree')
          assessment.symptomatic = assessment.symptomatic?
          queue.commit if assessment.save
        else
          # If message['reported_symptoms_array'] is not populated then this assessment came in through
          # a generic channel ie: SMS where monitorees are asked YES/NO if they are experiencing symptoms
          patient.active_dependents.each do |dependent|
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
            assessment = Assessment.new(reported_condition: reported_condition, patient: dependent)
            assessment.symptomatic = assessment.symptomatic? || message['experiencing_symptoms']
            # If current user in the collection of patient + patient dependents is the patient, then that means
            # that they reported for themselves, else we are creating an assessment for the dependent and
            # that means that it was the proxy who reported for them
            assessment.who_reported = patient.submission_token == dependent.submission_token ? 'Monitoree' : 'Proxy'
            queue.commit if assessment.save
          end
        end
      rescue JSON::ParserError
        Rails.logger.info 'ConsumeAssessmentsJob: skipping invalid message...'
        queue.commit
        next
      end
    end
  rescue Redis::ConnectionError, Redis::CannotConnectError => e
    Rails.logger.info "ConsumeAssessmentsJob: Redis::ConnectionError (#{e}), retrying..."
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
