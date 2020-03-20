# frozen_string_literal: true
require 'redis'

# ConsumeAssessmentsJob: Pulls assessments created in the split instance and saves them
class ConsumeAssessmentsJob < ApplicationJob
  queue_as :default

  def perform
    connection = Redis.new
    connection.subscribe 'reports' do |on|
      on.message do |_channel, msg|
        begin
          message = JSON.parse(msg)
          message = message.slice('threshold_condition_hash', 'reported_symptoms_array', 'patient_submission_token')
          next if message.nil?

          patient = Patient.find_by(submission_token: message['patient_submission_token'])
          next if patient.nil?

          # Prevent duplicate patient assessment spam
          unless patient.latest_assessment.nil? # Only check for latest assessment if there is one
            next if patient.latest_assessment.created_at > 15.minutes.ago
          end

          threshold_condition = ThresholdCondition.where(threshold_condition_hash: message['threshold_condition_hash']).first
          next unless threshold_condition

          reported_symptoms_array = message['reported_symptoms_array']
          typed_reported_symptoms = Condition.build_symptoms(reported_symptoms_array)
          reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: message['threshold_condition_hash'])
          assessment = Assessment.new(reported_condition: reported_condition)
          assessment.symptomatic = assessment.symptomatic?
          assessment.patient = patient
          assessment.who_reported = 'Monitoree'
          assessment.save!
        rescue JSON::ParserError
          next
        end
      end
    end
  end
end
