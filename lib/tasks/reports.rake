# frozen_string_literal: true

namespace :reports do
  desc "Receive and Process Reports"
  task receive_and_process_reports: :environment do
    ConsumeAssessmentsJob.perform_now
  end
end
