# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard/dashboard_verifier'
require_relative 'enrollment/form'
require_relative 'enrollment/form_validator'
require_relative 'enrollment/form_verifier'
require_relative 'patient_page/patient_page_verifier'
require_relative '../../lib/system_test_utils'

class EnrollerTestHelper < ApplicationSystemTestCase
  @@enroller_dashboard_verifier = EnrollerDashboardVerifier.new(nil)
  @@enrollment_form = EnrollmentForm.new(nil)
  @@enrollment_form_validator = EnrollmentFormValidator.new(nil)
  @@enrollment_form_verifier = EnrollmentFormVerifier.new(nil)
  @@enroller_patient_page_verifier = EnrollerPatientPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  MONITOREES = @@system_test_utils.monitorees
  USERS = @@system_test_utils.users
  PATIENTS = @@system_test_utils.patients

  def view_enrolled_monitorees(user_label)
    @@system_test_utils.login(user_label)
    @@enroller_dashboard_verifier.verify_enrolled_monitorees(user_label)
    @@system_test_utils.logout
  end

  def enroll_monitoree(user_label, monitoree_label, is_epi: false)
    monitoree = MONITOREES[monitoree_label]
    @@system_test_utils.login(user_label)
    click_on 'Enroll New Monitoree'
    @@enrollment_form.populate_monitoree_info(monitoree)
    @@enroller_patient_page_verifier.verify_monitoree_info(monitoree, is_epi: false)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@enroller_patient_page_verifier.verify_monitoree_info(monitoree, is_epi: is_epi)
    visit '/'
    @@enroller_dashboard_verifier.verify_monitoree_info_on_dashboard(monitoree, is_epi: is_epi)
    @@system_test_utils.logout
  end

  def enroll_group_member(user_label, existing_monitoree_label, new_monitoree_label, is_epi: false)
    existing_monitoree = MONITOREES[existing_monitoree_label]
    new_monitoree = MONITOREES[new_monitoree_label]
    @@system_test_utils.login(user_label)
    click_link 'Enroll New Monitoree'
    @@enrollment_form.populate_monitoree_info(existing_monitoree)
    @@enroller_patient_page_verifier.verify_monitoree_info(existing_monitoree)
    click_on 'Finish and Add a Household Member'
    click_on 'Continue'
    @@system_test_utils.wait_for_enrollment_submission
    @@enrollment_form.populate_monitoree_info(new_monitoree)
    @@enroller_patient_page_verifier.verify_group_member_info(existing_monitoree, new_monitoree)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@enroller_patient_page_verifier.verify_group_member_info(existing_monitoree, new_monitoree, is_epi: is_epi)
    visit '/'
    @@enroller_dashboard_verifier.verify_group_member_on_dashboard(existing_monitoree, new_monitoree, is_epi: is_epi)
    @@system_test_utils.logout
  end

  def enroll_monitoree_with_same_monitored_address(user_label, monitoree_label)
    monitoree = MONITOREES[monitoree_label]
    @@system_test_utils.login(user_label)
    click_link 'Enroll New Monitoree'
    @@enrollment_form.populate_enrollment_step(:identification, monitoree['identification'])
    @@enrollment_form.populate_enrollment_step(:address, monitoree['address'], continue: false)
    click_on 'Copy from Home Address'
    @@enrollment_form_verifier.verify_home_address_copied(monitoree)
    @@system_test_utils.logout
  end

  def enroll_monitoree_and_edit(user_label, existing_monitoree_label, new_monitoree_label)
    existing_monitoree = MONITOREES[existing_monitoree_label]
    new_monitoree = MONITOREES[new_monitoree_label]
    @@system_test_utils.login(user_label)
    click_on 'Enroll New Monitoree'
    @@enrollment_form.populate_monitoree_info(existing_monitoree)
    @@enroller_patient_page_verifier.verify_monitoree_info(existing_monitoree)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@enroller_patient_page_verifier.verify_monitoree_info(existing_monitoree)
    @@enrollment_form.edit_monitoree_info(new_monitoree)
    @@enroller_patient_page_verifier.verify_monitoree_info(new_monitoree)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@enroller_patient_page_verifier.verify_monitoree_info(new_monitoree)
    visit '/'
    @@enroller_dashboard_verifier.verify_monitoree_info_on_dashboard(new_monitoree)
    @@system_test_utils.logout
  end

  def enroll_monitoree_and_cancel(user_label, monitoree_label, is_epi: false)
    monitoree = MONITOREES[monitoree_label]
    @@system_test_utils.login(user_label)
    click_link 'Enroll New Monitoree'
    @@enrollment_form.populate_monitoree_info(monitoree)
    click_on 'Cancel'
    @@system_test_utils.wait_for_pop_up_alert
    page.driver.browser.switch_to.alert.dismiss
    @@system_test_utils.wait_for_pop_up_alert
    @@enroller_patient_page_verifier.verify_monitoree_info(monitoree)
    click_on 'Cancel'
    @@system_test_utils.wait_for_pop_up_alert
    page.driver.browser.switch_to.alert.accept
    @@enroller_dashboard_verifier.verify_monitoree_info_not_on_dashboard(monitoree, is_epi: is_epi)
    @@system_test_utils.logout
  end

  def verify_patient_page_permissions(user_label)
    user = User.find_by(email: USERS[user_label]['email'])
    monitoree = user.patients.first

    # Login and click on a monitoree
    @@system_test_utils.login(user_label)
    displayed_name = "#{monitoree.last_name}, #{monitoree.first_name}"
    click_on displayed_name

    @@enroller_patient_page_verifier.verify_monitoree_displayed_data(user)
    @@system_test_utils.logout
  end

  def verify_form_data_after_navigation(user_label, monitoree_label)
    @@system_test_utils.login(user_label)
    @@enrollment_form_verifier.verify_form_data_after_navigation(MONITOREES[monitoree_label])
    @@system_test_utils.logout
  end

  def verify_input_validation(user_label, monitoree_label)
    @@system_test_utils.login(user_label)
    @@enrollment_form_validator.verify_enrollment_input_validation(MONITOREES[monitoree_label])
    @@system_test_utils.logout
  end

  def view_enrollment_analytics(user_label)
    @@system_test_utils.login(user_label)
    click_on 'Analytics'
    @@enroller_dashboard_verifier.verify_enrollment_analytics
    @@system_test_utils.logout
  end

  def move_to_household(user_label, patient_label, target_hoh_label)
    first_name = PATIENTS[patient_label]['first_name']
    last_name = PATIENTS[patient_label]['last_name']
    displayed_name = "#{last_name}, #{first_name}"

    @@system_test_utils.login(user_label)
    fill_in 'Search', with: displayed_name
    click_on displayed_name
    @@enroller_patient_page_verifier.move_to_household(user_label, patient_label, target_hoh_label)
    @@system_test_utils.logout
  end
end
