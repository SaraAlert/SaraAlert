# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCaseEnrollerDashboard'

require_relative 'enroller_test_helper'

class EnrollerDashboardTest < ApplicationSystemTestCase
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

  test 'monitoree page permissions' do
    @@enroller_test_helper.verify_patient_page_permissions('state1_enroller')
    @@enroller_test_helper.verify_patient_page_permissions('state1_epi_enroller')
  end

  test 'move to household' do
    @@enroller_test_helper.move_to_household('state1_enroller', 'patient_1', 'patient_46')
  end
end
