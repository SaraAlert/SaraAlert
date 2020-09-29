# frozen_string_literal: true

namespace :subject do
  desc 'Run the close patients rake task'
  task close_patients: :environment do
    ClosePatientsJob.perform_later
  end
end
