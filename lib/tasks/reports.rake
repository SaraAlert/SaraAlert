# frozen_string_literal: true

require 'redis'
require 'redis-queue'
require 'json'

namespace :reports do
  desc 'Recieve reports from the Redis bridge queue, then move them over to the Sidekiq queue for processing'
  task queue_reports: :environment do
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
        process(queue, worker_number)
      end
    end
    Process.waitall
  end

  private

  def process(queue, worker_number)
    loop do
      @msg = queue.pop if @msg.nil?
      # If perform_async does not return a job_id (String), throw an error.
      # Error handling will take over retries.
      unless ConsumeAssessmentsJob.perform_async(@msg).match?(/[a-f0-9]{24}/)
        raise(RuntimeError, 'Sidekiq did not return successfully from perform_async')
      end

      queue.commit
      @sleep_seconds = 0
      @msg = nil
    end
  rescue RuntimeError, Redis::ConnectionError, Redis::CannotConnectError => e
    # If this point is reached with another 30 second sleep: drop the message, log, and process the next (if the error was with ).
    if @sleep_seconds == 30
      handle_complete_failure(e, worker_number)
    else
      handle_successive_timeout(e, worker_number)
    end
    retry
  end

  def handle_complete_failure(error, worker_number)
    # In an effort to not log any PHI or PII the message needs to be parsed a little.
    submission_token = JSON.parse(@msg)&.slice('patient_submission_token')
    raise JSON::ParserError, 'JSON parsed correctly but no submission_token was found' if submission_token.empty?

    Rails.logger.error("reports:queue_reports process #{worker_number}: Unable to process a report for #{submission_token} because of #{error}. \
                        The report has been skipped.")
    # Setting @msg to nil will grab the next entry from the queue on retry
  rescue JSON::ParserError
    # Do not print the JSON parser error. If the incomming report is legitimate, there is a good chance the ParserError will contain PHI or PII.
    Rails.logger.error("reports:queue_reports process #{worker_number}: Unable to process a report because of #{error}. \
                        No submission token could be parsed; the report failed parsing. The report has been skipped.")
  ensure
    @msg = nil
  end

  def handle_successive_timeout(error, worker_number)
    @sleep_seconds = exponential_backoff(@sleep_seconds)
    Rails.logger.info("reports:queue_reports process #{worker_number}: #{error}, retrying in #{@sleep_seconds} seconds.")
    sleep(@sleep_seconds)
  end

  def exponential_backoff(seconds)
    if seconds > 16
      # Maximum of 30 second backoff
      30
    elsif seconds.zero?
      1 + rand
    elsif seconds.floor == 1
      2 + rand
    else
      (seconds.floor**2) + rand
    end
  end

  def trap_interrupt_signal
    Signal.trap('INT') do
      # Interrupted before Processes are created
      return if @processes.empty?

      # Exit all child processes, avoid zombies
      Process.kill('TERM', 0)
    end
  end
end
