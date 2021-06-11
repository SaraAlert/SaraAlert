# frozen_string_literal: true

require 'redis'
require 'redis-queue'
require 'json'
require_relative '../reports_helper'

namespace :reports do
  desc 'Recieve reports from the Redis bridge queue, then move them over to the Sidekiq queue for processing'
  task queue_reports: :environment do
    include ReportsHelper
    trap_interrupt_signal
    number_of_processes = ENV.fetch('CONSUME_WORKERS', 8).to_i
    Rails.logger.info("Starting the reports:queue_reports task with #{number_of_processes} processes.")
    @processes = []
    number_of_processes.times do |worker_number|
      @processes << Process.fork do
        Rails.logger.info("reports:queue_reports process #{worker_number} starting.")
        queue = Redis::Queue.new('q_bridge', 'bp_q_bridge', redis: Rails.application.config.redis)
        Rails.logger.info("reports:queue_reports process #{worker_number} listening on queue: #{queue.instance_values}")
        @sleep_seconds = 0
        ReportsHelper.process(queue, worker_number)
      end
    end
    Process.waitall
  end

  private

  def trap_interrupt_signal
    Signal.trap('INT') do
      # Interrupted before Processes are created
      return if @processes.empty?

      # Exit all child processes, avoid zombies
      Process.kill('TERM', 0)
    end
  end
end
