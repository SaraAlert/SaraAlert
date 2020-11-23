# frozen_string_literal: true

require 'redis'
require 'redis-queue'

namespace :reports do
  desc "Receive and Process Reports"
  task queue_reports: :environment do
    Rails.logger.info('Starting the ConsumeAssessments task')
    queue = Redis::Queue.new('q_bridge', 'bp_q_bridge', redis: Rails.application.config.redis)

    while(msg = queue.pop)
      ConsumeAssessmentsWorker.perform_async(msg)
    end
  rescue Redis::ConnectionError, Redis::CannotConnectError => e
    Rails.logger.info("ConsumeAssessmentsJob: Redis::ConnectionError (#{e}), retrying")
    sleep(1)
    retry
  end
end
