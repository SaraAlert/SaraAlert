# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCaseEnrollerEnrollment'

require_relative 'enroller_test_helper'

class EnrollerEnrollmentTest < ApplicationSystemTestCase
  @@enroller_test_helper = EnrollerTestHelper.new(nil)

  test 'enroll monitoree with all fields' do
    @@enroller_test_helper.enroll_monitoree('state1_epi_enroller', 'monitoree_2', is_epi: true)
  end

  test 'enroll monitoree with only required fields' do
    @@enroller_test_helper.enroll_monitoree('locals1c2_enroller', 'monitoree_3')
  end

  test 'enroll monitoree with jurisdiction within hierarchy' do
    @@enroller_test_helper.enroll_monitoree('state1_enroller', 'monitoree_5')
  end

  test 'epi enroll monitoree with any jurisdiction' do
    @@enroller_test_helper.enroll_monitoree('state1_epi_enroller', 'monitoree_1', is_epi: true)
  end

  test 'add group member' do
    @@enroller_test_helper.enroll_group_member('state2_enroller', 'monitoree_6', 'monitoree_7')
  end

  test 'add group member with foreign address and international additional planned travel' do
    @@enroller_test_helper.enroll_group_member('locals2c3_enroller', 'monitoree_4', 'monitoree_9')
  end
end
