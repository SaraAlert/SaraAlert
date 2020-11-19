# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthDashboard'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthDashboardTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'verify patient information on dashboard' do
    @@public_health_test_helper.verify_patients_on_dashboard('locals1c2_epi', verify_scope: false)
  end

  test 'verify jurisdiction scope filtering logic on dashboard for state epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('state1_epi_enroller', verify_scope: true)
  end

  test 'verify jurisdiction scope filtering logic on dashboard for local epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('locals1c1_epi', verify_scope: true)
  end

  test 'verify assigned user filtering logic on dashboard for state epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('state2_epi', verify_scope: false)
  end

  test 'verify assigned user filtering logic on dashboard for local epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('locals2c3_epi', verify_scope: false)
    @@public_health_test_helper.verify_patients_on_dashboard('locals2c4_epi', verify_scope: false)
  end
end
