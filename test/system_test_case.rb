# frozen_string_literal: true

require 'test_helper'
require 'minitest/retry'

SimpleCov.command_name 'SystemTestCase'

class ActionDispatch::SystemTestCase
  Minitest::Retry.use!
  fixtures :all
end
