# frozen_string_literal: true

require 'test_helper'
require 'minitest/retry'

class ActionDispatch::SystemTestCase
  Minitest::Retry.use!
  fixtures :all
end
