# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'components/monitoree_enrollment/dashboard'
require_relative 'components/monitoree_enrollment/form'
require_relative 'lib/system_test_utils'

class EnrollerTest < ApplicationSystemTestCase
  @@monitoree_enrollment_dashboard = MonitoreeEnrollmentDashboard.new(nil)
  @@monitoree_enrollment_form = MonitoreeEnrollmentForm.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'state enroller enroll monitoree with all fields' do
    @@monitoree_enrollment_form.enroll_monitoree('locals1c1_enroller', 'monitoree_2')
  end

  test 'local enroller enroll monitoree with only necessary fields' do
    @@monitoree_enrollment_form.enroll_monitoree('locals1c2_enroller', 'monitoree_3')
  end

  test 'state epi enroller enroll monitoree with foreign address' do
    @@monitoree_enrollment_form.enroll_monitoree('state1_epi_enroller', 'monitoree_4')
  end

  test 'state epi enroller enroll monitoree with all races and exposure risks' do
    @@monitoree_enrollment_form.enroll_monitoree('state1_epi_enroller', 'monitoree_5')
  end

  test 'local enroller add group member after enrolling monitoree with international additional planned travel' do
    @@monitoree_enrollment_form.enroll_monitorees_in_group('locals2c3_enroller', 'monitoree_6', 'monitoree_7')
  end

  test 'state epi enroller add group member after enrolling monitoree with domestic additional planned travel' do
    @@monitoree_enrollment_form.enroll_monitorees_in_group('state1_epi_enroller', 'monitoree_2', 'monitoree_8')
  end

  test 'local enroller add group member after enrolling monitoree with foreign address' do
    @@monitoree_enrollment_form.enroll_monitorees_in_group('locals2c4_enroller', 'monitoree_4', 'monitoree_9')
  end

  test 'copy home address to monitored address when copy from home address button is clicked' do
    @@monitoree_enrollment_form.enroll_monitoree_with_same_monitored_address_as_home('state2_enroller', 'monitoree_10')
  end

  test 'input validation' do
    @@monitoree_enrollment_form.verify_enrollment_input_validation('state2_enroller', 'monitoree_11')
  end

  test 'preserve form data between different sections if next or previous are clicked' do
    @@monitoree_enrollment_form.verify_form_data_after_navigation('locals2c3_enroller', 'monitoree_12')
  end

  test 'edit data on the review page' do
    @@monitoree_enrollment_form.enroll_monitoree_and_edit_data_on_review_page('state1_enroller', 'monitoree_11', 'monitoree_12')
  end

  test 'edit existing data' do
    @@monitoree_enrollment_form.enroll_monitoree_and_edit_info('locals1c1_enroller', 'monitoree_3', 'monitoree_6')
  end

  test 'cancel monitoree enrollment via cancel button' do
    @@monitoree_enrollment_form.enroll_monitoree_and_cancel('locals2c3_enroller', 'monitoree_10', 'Cancel')
  end

  test 'cancel monitoree enrollment via return to dashboard link' do
    @@monitoree_enrollment_form.enroll_monitoree_and_cancel('locals2c4_enroller', 'monitoree_1', 'Return To Dashboard')
  end

  test 'view enrollment analytics' do
    @@monitoree_enrollment_dashboard.login_and_view_enrollment_analytics('locals2c4_enroller')
  end
end
