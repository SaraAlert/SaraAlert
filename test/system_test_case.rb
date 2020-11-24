# frozen_string_literal: true

require 'test_helper'
require 'minitest/retry'

class ActionDispatch::SystemTestCase
  Minitest::Retry.use! if ENV['APP_IN_CI']
  fixtures :all

  Rails.application.configure do
    config.x.executing_system_tests = true
  end
end
