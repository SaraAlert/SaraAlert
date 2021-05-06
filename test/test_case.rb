# frozen_string_literal: true

require 'test_helper'
require 'rspec/mocks/minitest_integration'

SimpleCov.command_name 'TestCase'

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  fixtures :all

  def setup
    Sidekiq::Worker.clear_all
  end

  # Make corrections for the edge of DST.
  #
  # NOTE: One main assumption of this function is that `time` will only ever
  # be right now or in the past (i.e. NOT in the future).
  #
  # When on the edge of DST changes we want to make corrections such that
  # we write times that are on the correct day that we intend.
  # Example:
  # - Reporting period minutes is 2 days
  # - DST +1 hour occurs at 2021-02-14T00:00:00 Eastern
  # - The previous notification eligibility edge should be at 2021-02-13T00:00:00-5:00
  # - The next notification eligibility edge window should be at 2021-02-15T00:00:00-4:00
  # So, we need to correct times before 2021-02-14T00:00:00 to have the
  # extra -1 offset.
  # We also need to do the opposite when on the other side of DST.
  #
  # Params:
  # - Patient patient: The patient to possibly correct time for
  # - Time time: Any time object instance
  #
  # Returns: Time that has been corrected if necessary
  def correct_dst_edge(patient, time)
    if dst_ended?(patient, time)
      time - 1.hour
    elsif dst_started?(patient, time)
      time + 1.hour
    else
      time
    end
  end

  def dst_ended?(patient, time)
    patient_dst_info = dst_info(patient, time)

    !patient_dst_info[:patient_in_dst] && patient_dst_info[:patient_was_dst]
  end

  def dst_started?(patient, time)
    patient_dst_info = dst_info(patient, time)

    patient_dst_info[:patient_in_dst] && !patient_dst_info[:patient_was_dst]
  end

  # Run tests in parallel with specified workers
  parallelize(workers: 1)

  self.use_transactional_tests = true
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end

class ActionDispatch::IntegrationTest
  def after_teardown
    super
    FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
  end

  def sign_in(user)
    post user_session_path 'user[email]' => user.email, 'user[password]' => user.password
  end
end

private

def dst_info(patient, time)
  {
    patient_in_dst: Time.now.getlocal(patient.address_timezone_offset).in_time_zone(patient.time_zone).dst?,
    patient_was_dst: time.in_time_zone(patient.time_zone).dst?
  }
end
