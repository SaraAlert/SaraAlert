# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'minitest/retry'
Minitest::Retry.use!

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  if ENV['CI'] == 'true'
    parallelize(workers: 8)
  else
    parallelize(workers: 1)
  end

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
  self.use_transactional_tests = true
end
