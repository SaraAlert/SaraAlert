# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../benchmark'

# Time Threshold: 8 minutes
# Setup: Changes many patients to be close_eligible
benchmark(
  name: 'ClosePatientsJob',
  time_threshold: 8 * 60,
  setup: proc {
    puts 'updating patients'
    max_num_to_close = 20_000
    Patient.limit(max_num_to_close).update_all(
      isolation: false,
      continuous_exposure: false,
      latest_assessment_at: DateTime.now,
      symptom_onset: nil,
      public_health_action: 'None',
      purged: false,
      monitoring: true,
      created_at: 100.days.ago,
      last_date_of_exposure: 100.days.ago
    )
  }
) { ClosePatientsJob.perform_now }
