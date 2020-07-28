# frozen_string_literal: true

require 'test_helper'
require 'rspec/mocks/minitest_integration'

SimpleCov.command_name 'TestCase'

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  fixtures :all

  def setup
    create(:enroller)
    create(:public_health)
    create(:public_health_enroller)
    create(:admin)
    create(:analyst)
    Sidekiq::Worker.clear_all
  end

  # Run tests in parallel with specified workers
  parallelize(workers: 1)

  self.use_transactional_tests = true
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end
