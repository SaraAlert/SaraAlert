# frozen_string_literal: true

require 'redis'

# ConsumeAssessmentsJob: Pulls assessments created in the split instance and saves them
class ConsumeAssessmentsJob < ApplicationJob
  queue_as :default

  def perform
    connection = Redis.new
    connection.subscribe 'reports' do |on|
      on.message do |_channel, msg|
        message = JSON.parse(msg)
        message = message.slice('threshold_condition_hash', 'reported_symptoms_array', 'patient_submission_token', 'experiencing_symptoms')
        next if message.nil?

        patient = Patient.find_by(submission_token: message['patient_submission_token'])
        next if patient.nil?

        # Prevent duplicate patient assessment spam
        unless patient.latest_assessment.nil? # Only check for latest assessment if there is one
          next if patient.latest_assessment.created_at > ADMIN_OPTIONS['reporting_limit'].minutes.ago
        end
        threshold_condition = ThresholdCondition.where(threshold_condition_hash: message['threshold_condition_hash']).first
        next unless threshold_condition

        if message['reported_symptoms_array']
          reported_symptoms_array = message['reported_symptoms_array']
          typed_reported_symptoms = Condition.build_symptoms(reported_symptoms_array)
          reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: message['threshold_condition_hash'])
          assessment = Assessment.new(reported_condition: reported_condition)
          assessment.symptomatic = assessment.symptomatic? || message['experiencing_symptoms']
          assessment.patient = patient
          assessment.who_reported = 'Monitoree'
          assessment.save!
        else
          # If message['reported_symptoms_array'] is not populated then this assessment came in through
          # a generic channel ie: SMS where monitorees are asked YES/NO if they are experiencing symptoms
          ([patient] + patient.dependents).uniq.each do |pat|
            if message['experiencing_symptoms']
              # Remove values so that the values will appear as blank in a symptomatic report
              # this will indicate that the person needs to be reached out to to get the actual values
              typed_reported_symptoms = threshold_condition.clone_symptoms_remove_values
            else
              # The person is not experiencing symptoms, we can infer that the bool symptoms are the opposite
              # of the threshold values that represent symptomatic (most likely false)
              typed_reported_symptoms = threshold_condition.clone_symptoms_negate_bool_values
            end
            reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: message['threshold_condition_hash'])
            assessment = Assessment.new(reported_condition: reported_condition)
            assessment.symptomatic = assessment.symptomatic? || message['experiencing_symptoms']
            assessment.patient = pat
            # If current user in the collection of patient + patient dependents is the patient, then that means
            # that they reported for themselves, else we are creating an assessment for the dependent and
            # that means that it was the proxy who reported for them
            if message['patient_submission_token'] == pat.submission_token
              assessment.who_reported = 'Monitoree'
            else
              assessment.who_reported = 'Proxy'
            end
            assessment.save!
          end
        end

      rescue JSON::ParserError
        next
      end
    end
  end
end
