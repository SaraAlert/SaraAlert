# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../benchmark'

benchmark(
  name: 'SendAssessmentsJob',
  time_threshold: 25 * 60 # 25 minutes
) { SendAssessmentsJob.perform_now }
