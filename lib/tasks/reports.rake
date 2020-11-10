# frozen_string_literal: true

require 'redis'
require 'redis-queue'

namespace :reports do
  desc "Receive and Process Reports"
  task receive_and_process_reports: :environment do
    tries = 0
    queue = Redis::Queue.new('q_bridge', 'bp_q_bridge', redis: Rails.application.config.redis)

    while(msg = queue.pop)
      ConsumeAssessmentsWorker.perform_now(msg)
    end
  rescue Redis::ConnectionError, Redis::CannotConnectError => e
    Rails.logger.info "ConsumeAssessmentsJob: Redis::ConnectionError (#{e}), retrying..."
    if tries < 3
      tries += 1
      sleep(1)
      retry
    else
      Rails.logger.info "ConsumeAssessmentsJob: Redis connection error > 3 times, cancelling queuing of this message."
      Rails.logger.info "Dropped Message: #{msg}"
      tries = 0
    end
  end
end
