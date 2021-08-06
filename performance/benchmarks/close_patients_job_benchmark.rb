# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../benchmark'

# Time Threshold: 10 minutes
# Setup: Changes many patients to be close_eligible
benchmark(
  name: 'ClosePatientsJob',
  time_threshold: 10 * 60,
  setup: proc {
    puts 'updating patients'
    max_num_to_close = 20_000
    # Due to the `no_recent_activity` criteria of the close_eligible scope
    # it is necessary to change the updated_at of all patients so that
    # we do not go over `max_num_to_close`
    # Skip model validations as they are not needed in the benchmark.
    # rubocop:disable Rails/SkipsModelValidations
    Patient.update_all(updated_at: DateTime.now)
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
    # rubocop:enable Rails/SkipsModelValidations
  }
) { ClosePatientsJob.perform_now }
