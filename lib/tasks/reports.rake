# frozen_string_literal: true

namespace :reports do
  desc "Receive and Process Reports"
  task receive_and_process_reports: :environment do
    min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { 4 }
    min_threads_count.times do
      Process.fork do
        ConsumeAssessmentsJob.perform_now
      end
    end
    Process.waitall
  end
end
