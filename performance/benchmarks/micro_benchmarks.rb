# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../benchmark'

def divider
  puts "\n\n#{'-' * 80}\n\n"
end

micro_results = []

# Time Threshold: 15 seconds (This is just for a baseline)
micro_results << benchmark(
  name: 'PatientCountBaseline',
  time_threshold: 15,
  no_exit: true
) { Patient.count }

divider

# Time Threshold: 7 seconds
# Setup: Changes time to around 1pm Eastern
# Teardown: Returns to current time
micro_results << benchmark(
  name: 'PatientReminderEligible',
  time_threshold: 7,
  no_exit: true,
  setup: proc { Timecop.travel(Time.now.utc.change(hour: 18)) },
  teardown: proc { Timecop.return }
) { Patient.reminder_eligible.count }

divider

# This micro test actually modifies the database,
# so it is best to leave it as the last benchmark.
# Time Threshold: 7 seconds
# Setup: Changes many patients to be close_eligible
micro_results << benchmark(
  name: 'PatientCloseEligible',
  time_threshold: 7,
  no_exit: true,
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
) { Patient.close_eligible.count }

divider

if micro_results.include? false
  puts 'ONE OR MORE MICRO BENCHMARKS FAILED'
  exit(1)
else
  puts 'ALL MICRO BENCHMARKS PASSED'
  exit(0)
end
