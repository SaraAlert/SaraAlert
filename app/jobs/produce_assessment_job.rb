# frozen_string_literal: true

require 'redis'
require 'redis-queue'

# ProduceAssessmentJob: Publish a new assessment to redis to be consumed later
class ProduceAssessmentJob < ApplicationJob
  queue_as :default

  def perform(assessment)
    queue = Redis::Queue.new('q_bridge', 'bp_q_bridge', redis: Rails.application.config.redis)
    report = {
      response_status: assessment['response_status'],
      threshold_condition_hash: assessment['threshold_hash'],
      reported_symptoms_array: assessment['symptoms'],
      experiencing_symptoms: assessment['experiencing_symptoms'],
      patient_submission_token: assessment['patient_submission_token']
    }
    queue.push report.to_json
  end
end
