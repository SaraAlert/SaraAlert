# frozen_string_literal: true
namespace :reports do
  desc "Receive and Process Reports"
  task receive_and_process_reports: :environment do
    pids = []

    consume_workers = ENV.fetch("CONSUME_WORKERS") { 8 }
    consume_workers.times do
      pids << Process.fork { ConsumeAssessmentsJob.perform_now }
    end

    # Process.waitall was not properly exiting for an unknown reason.
    # Waiting for each PID allows the task to exit properly once all of the forks exit.
    pids.each{ |pid| Process.wait pid }
  end
end