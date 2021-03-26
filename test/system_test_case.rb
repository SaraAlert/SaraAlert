# frozen_string_literal: true

require 'test_helper'
require 'minitest/retry'

class ActionDispatch::SystemTestCase
  Minitest::Retry.use! if ENV['APP_IN_CI']
  fixtures :all
end
