# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'lib/monitoree_enrollment/helper'

class EnrollerTest < ApplicationSystemTestCase
  @@monitoree_enrollment_helper = MonitoreeEnrollmentHelper.new(nil)

  test 'state enroller enroll monitoree with all fields' do
    @@monitoree_enrollment_helper.enroll_monitoree('locals1c1_enroller', 'monitoree_2')
  end

  test 'local enroller enroll monitoree with only necessary fields' do
    @@monitoree_enrollment_helper.enroll_monitoree('locals1c2_enroller', 'monitoree_3')
  end

  test 'state epi enroller enroll monitoree with foreign address' do
    @@monitoree_enrollment_helper.enroll_monitoree('state1_epi_enroller', 'monitoree_4', true)
  end

  test 'state epi enroller enroll monitoree with all races and exposure risks' do
    @@monitoree_enrollment_helper.enroll_monitoree('state1_epi_enroller', 'monitoree_5', true)
  end

  test 'local enroller add group member after enrolling monitoree with international additional planned travel' do
    @@monitoree_enrollment_helper.enroll_monitorees_in_group('locals2c3_enroller', 'monitoree_6', 'monitoree_7')
  end

  test 'state epi enroller add group member after enrolling monitoree with domestic additional planned travel' do
    @@monitoree_enrollment_helper.enroll_monitorees_in_group('state1_epi_enroller', 'monitoree_2', 'monitoree_8', true)
  end

  test 'local enroller add group member after enrolling monitoree with foreign address' do
    @@monitoree_enrollment_helper.enroll_monitorees_in_group('locals2c4_enroller', 'monitoree_4', 'monitoree_9')
  end

  test 'copy home address to monitored address when copy from home address button is clicked' do
    @@monitoree_enrollment_helper.enroll_monitoree_with_same_monitored_address_as_home('state2_enroller', 'monitoree_10')
  end

  test 'input validation' do
    @@monitoree_enrollment_helper.verify_enrollment_input_validation('state2_enroller', 'monitoree_11')
  end

  test 'preserve form data between different sections if next or previous are clicked' do
    @@monitoree_enrollment_helper.verify_form_data_after_navigation('locals2c3_enroller', 'monitoree_12')
  end

  test 'edit data on the review page' do
    @@monitoree_enrollment_helper.enroll_monitoree_and_edit_data_on_review_page('state1_enroller', 'monitoree_11', 'monitoree_12')
  end

  test 'edit existing data' do
    @@monitoree_enrollment_helper.enroll_monitoree_and_edit_info('locals1c1_enroller', 'monitoree_3', 'monitoree_6')
  end

  test 'cancel monitoree enrollment' do
    @@monitoree_enrollment_helper.enroll_monitoree_and_cancel('locals2c3_enroller', 'monitoree_10')
  end

  test 'view enrollment analytics' do
    @@monitoree_enrollment_helper.view_enrollment_analytics('state1_enroller')
  end
end
