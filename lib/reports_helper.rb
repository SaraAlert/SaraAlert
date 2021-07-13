# frozen_string_literal: true

# Processing and error handling for reports:queue_reports
# Enables easier unit testing of these methods.
module ReportsHelper
  def process(queue, worker_number)
    loop do
      @msg = queue.pop if @msg.nil?
      # If perform_async does not return a job_id (String), throw an error.
      # Error handling will take over retries.
      raise('Sidekiq did not return successfully from perform_async') unless ConsumeAssessmentsJob.perform_async(@msg).match?(/[a-f0-9]{24}/)

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

    raise 'JSON parsed correctly but no submission_token was found' if submission_token.empty?

    Rails.logger.error("reports:queue_reports process #{worker_number}: Unable to process a report for #{submission_token} because of #{error}. The report has been skipped.")
  rescue JSON::ParserError
    # Do not print the JSON parser error. If the incomming report is legitimate, there is a good chance the ParserError will contain PHI or PII.
    # Instead, print the original error from Redis or Sidekiq
    Rails.logger.error("reports:queue_reports process #{worker_number}: Unable to process a report because of #{error}. No submission token could be parsed; the report failed parsing. The report has been skipped.")
  rescue RuntimeError => e
    Rails.logger.error("reports:queue_reports process #{worker_number}: #{e}. Original error: #{error}")
  ensure
    # Setting @msg to nil will grab the next entry from the queue on retry
    @msg = nil
  end

  def handle_successive_timeout(error, worker_number)
    @sleep_seconds = exponential_backoff(@sleep_seconds)
    Rails.logger.info("reports:queue_reports process #{worker_number}: #{error}, retrying in #{@sleep_seconds} seconds.")
    sleep(@sleep_seconds)
  end

  def exponential_backoff(seconds)
    if seconds > Math.sqrt(30)
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
end
