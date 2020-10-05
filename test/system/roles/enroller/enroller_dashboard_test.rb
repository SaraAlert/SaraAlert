# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCaseEnrollerDashboard'

require_relative 'enroller_test_helper'

class EnrollerTest < ApplicationSystemTestCase
  @@enroller_test_helper = EnrollerTestHelper.new(nil)

  test 'view enrolled monitorees' do
    @@enroller_test_helper.view_enrolled_monitorees('state1_epi_enroller')
    @@enroller_test_helper.view_enrolled_monitorees('locals1c1_enroller')
    @@enroller_test_helper.view_enrolled_monitorees('locals1c2_enroller')
    @@enroller_test_helper.view_enrolled_monitorees('state2_enroller')
    @@enroller_test_helper.view_enrolled_monitorees('locals2c3_enroller')
    @@enroller_test_helper.view_enrolled_monitorees('locals2c4_enroller')
  end

  test 'view enrollment analytics' do
    @@enroller_test_helper.view_enrollment_analytics('state1_enroller')
  end

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

  test 'copy home address to monitored address' do
    @@enroller_test_helper.enroll_monitoree_with_same_monitored_address('state2_enroller', 'monitoree_10')
  end

  test 'preserve form data between enrollment steps' do
    @@enroller_test_helper.verify_form_data_after_navigation('locals2c3_enroller', 'monitoree_12')
  end

  test 'input validation' do
    @@enroller_test_helper.verify_input_validation('state2_enroller', 'monitoree_11')
  end

  test 'edit monitoree enrollment' do
    @@enroller_test_helper.enroll_monitoree_and_edit('state1_enroller', 'monitoree_11', 'monitoree_12')
  end

  test 'cancel enrollment' do
    @@enroller_test_helper.enroll_monitoree_and_cancel('locals2c3_enroller', 'monitoree_10')
  end
end
