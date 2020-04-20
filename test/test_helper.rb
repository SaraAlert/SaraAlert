# frozen_string_literal: true

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter if ENV['LOCAL_COVERAGE']

# Generate Github Actions compatible report
if ENV['APP_IN_CI']
  SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
end

SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  def setup
    create(:enroller)
    create(:public_health)
    create(:public_health_enroller)
    create(:admin)
  end

  # Run tests in parallel with specified workers
  parallelize(workers: 1)
  self.use_transactional_tests = true
end
