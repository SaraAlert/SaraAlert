# frozen_string_literal: true

require 'test_helper'

SimpleCov.command_name 'TestCase'

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  def setup
    create(:enroller)
    create(:public_health)
    create(:public_health_enroller)
    create(:admin)
    create(:analyst)
  end

  # Run tests in parallel with specified workers
  parallelize(workers: 1)

  self.use_transactional_tests = true
end
