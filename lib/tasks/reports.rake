require 'redis'
require 'json'
namespace :reports do

  desc "Receive and Process Reports"
  task receive_and_process_reports: :environment do
    connection = Redis.new
    connection.subscribe 'reports' do |on|
      on.message do |channel, msg|
        begin
          message = JSON.parse(msg)
          patient = Patient.find_by(submission_token: message['patient_submission_token'])
          threshold_condition = ThresholdCondition.where(threshold_condition_hash: message['threshold_condition_hash']).first
          reported_symptoms_array = message['reported_symptoms_array']
          typed_reported_symptoms = Condition.build_symptoms(reported_symptoms_array)
          reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: message['threshold_condition_hash'])
          @assessment = Assessment.new(reported_condition: reported_condition)
          @assessment.symptomatic = @assessment.symptomatic?
          @assessment.patient = patient
          @assessment.who_reported = 'Monitoree'
          @assessment.save!
        rescue
        end
      end
    end
  end
end
