# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../benchmark'

# Time Threshold: 10 minutes
# NOTE: Using Timecop here appears to cause this job in GitHub actions to
#       hang indefinitely.
#       Timecop commands are:
#           setup: proc { Timecop.travel(Time.now.utc.change(hour: 18)) },
#           teardown: proc { Timecop.return }
benchmark(
  name: 'SendAssessmentsJob',
  time_threshold: 10 * 60
) { SendAssessmentsJob.perform_now }
