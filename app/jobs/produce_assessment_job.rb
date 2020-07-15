# frozen_string_literal: true

require 'redis'

# ProduceAssessmentJob: Publish a new assessment to redis to be consumed later
class ProduceAssessmentJob < ApplicationJob
  queue_as :default

  def perform(assessment)
    connection = Redis.new
    report = {
      response_status: assessment['response_status'],
      threshold_condition_hash: assessment['threshold_hash'],
      reported_symptoms_array: assessment['symptoms'],
      experiencing_symptoms: assessment['experiencing_symptoms'],
      patient_submission_token: assessment['patient_submission_token']
    }
    # report.except!(:reported_symptoms_array) if report[:reported_symptoms_array].blank?
    connection.publish 'reports', report.to_json
  rescue Redis::ConnectionError, Redis::CannotConnectError => e
    puts "ProduceAssessmentJob: Redis::ConnectionError (#{e}), retrying..."
    sleep(1)
    retry
  end
end
