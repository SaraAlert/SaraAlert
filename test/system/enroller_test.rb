# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'lib/monitoree_enrollment/helper'

class EnrollerTest < ApplicationSystemTestCase
  @@monitoree_enrollment_helper = MonitoreeEnrollmentHelper.new(nil)

  test 'enroll monitoree with all fields' do
    @@monitoree_enrollment_helper.enroll_monitoree('state1_epi_enroller', 'monitoree_2', true)
  end

  test 'enroll monitoree with only required fields' do
    @@monitoree_enrollment_helper.enroll_monitoree('locals1c2_enroller', 'monitoree_3')
  end

  test 'enroll monitoree with jurisdiction within hierarchy' do
    @@monitoree_enrollment_helper.enroll_monitoree('state1_enroller', 'monitoree_5', false)
  end

  test 'epi enroll monitoree with any jurisdiction' do
    @@monitoree_enrollment_helper.enroll_monitoree('state1_epi_enroller', 'monitoree_2', true)
  end

  test 'add group member with foreign address and international additional planned travel' do
    @@monitoree_enrollment_helper.enroll_group_member('locals2c3_enroller', 'monitoree_4', 'monitoree_9')
  end

  test 'copy home address to monitored address' do
    @@monitoree_enrollment_helper.enroll_monitoree_with_same_monitored_address('state2_enroller', 'monitoree_10')
  end

  test 'input validation' do
    @@monitoree_enrollment_helper.verify_input_validation('state2_enroller', 'monitoree_11')
  end

  test 'preserve form data between enrollment steps' do
    @@monitoree_enrollment_helper.verify_form_data_after_navigation('locals2c3_enroller', 'monitoree_12')
  end

  test 'enroll monitoree and edit' do
    @@monitoree_enrollment_helper.enroll_monitoree_and_edit('state1_enroller', 'monitoree_11', 'monitoree_12')
  end

  test 'cancel enrollment' do
    @@monitoree_enrollment_helper.enroll_monitoree_and_cancel('locals2c3_enroller', 'monitoree_10')
  end

  test 'view enrollment analytics' do
    @@monitoree_enrollment_helper.view_enrollment_analytics('state1_enroller')
  end
end
