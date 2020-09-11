# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthDashboard'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'verify patient information on dashboard' do
    @@public_health_test_helper.verify_patients_on_dashboard('locals1c2_epi', false)
  end

  test 'verify jurisdiction scope filtering logic on dashboard for state epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('state1_epi_enroller', true)
  end

  test 'verify jurisdiction scope filtering logic on dashboard for local epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('locals1c1_epi', true)
  end

  test 'verify assigned user filtering logic on dashboard for state epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('state2_epi', false)
  end

  test 'verify assigned user filtering logic on dashboard for local epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('locals2c3_epi', false)
    @@public_health_test_helper.verify_patients_on_dashboard('locals2c4_epi', false)
  end

  test 'verify patient details and reports' do
    @@public_health_test_helper.view_patients_details_and_reports('state1_epi')
    @@public_health_test_helper.view_patients_details_and_reports('state2_epi')
  end
end
