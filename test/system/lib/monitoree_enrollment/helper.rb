# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard_verifier'
require_relative 'form'
require_relative 'form_validator'
require_relative 'form_verifier'
require_relative 'info_page_verifier'
require_relative '../system_test_utils'

class MonitoreeEnrollmentHelper < ApplicationSystemTestCase
  @@monitoree_enrollment_dashboard_verifier = MonitoreeEnrollmentDashboardVerifier.new(nil)
  @@monitoree_enrollment_form = MonitoreeEnrollmentForm.new(nil)
  @@monitoree_enrollment_form_validator = MonitoreeEnrollmentFormValidator.new(nil)
  @@monitoree_enrollment_form_verifier = MonitoreeEnrollmentFormVerifier.new(nil)
  @@monitoree_enrollment_info_page_verifier = MonitoreeEnrollmentInfoPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  MONITOREES = @@system_test_utils.get_monitorees

  def enroll_monitoree(user_label, monitoree_label, is_epi=false)
    monitoree = MONITOREES[monitoree_label]
    @@system_test_utils.login(user_label)
    click_on 'Enroll New Monitoree'
    @@monitoree_enrollment_form.populate_monitoree_info(monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree, false)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree, is_epi)
    visit '/'
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(monitoree, is_epi)
    @@system_test_utils.logout
  end

  def enroll_group_member(user_label, existing_monitoree_label, new_monitoree_label, is_epi=false)
    existing_monitoree = MONITOREES[existing_monitoree_label]
    new_monitoree = MONITOREES[new_monitoree_label]
    @@system_test_utils.login(user_label)
    click_link 'Enroll New Monitoree'
    @@monitoree_enrollment_form.populate_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree, false)
    click_on 'Finish and Add a Household Member'
    click_on 'Continue'
    @@system_test_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_form.populate_monitoree_info(new_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_group_member_info(existing_monitoree, new_monitoree, false)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_info_page_verifier.verify_group_member_info(existing_monitoree, new_monitoree, is_epi)
    visit '/'
    @@monitoree_enrollment_dashboard_verifier.verify_group_member_on_dashboard(existing_monitoree, new_monitoree, is_epi)
    @@system_test_utils.logout
  end

  def enroll_monitoree_with_same_monitored_address(user_label, monitoree_label)
    monitoree = MONITOREES[monitoree_label]
    @@system_test_utils.login(user_label)
    click_link 'Enroll New Monitoree'
    @@monitoree_enrollment_form.populate_enrollment_step(:identification, monitoree['identification'])
    @@monitoree_enrollment_form.populate_enrollment_step(:address, monitoree['address'], false)
    click_on 'Copy from Home Address'
    @@monitoree_enrollment_form_verifier.verify_home_address_copied(monitoree)
    @@system_test_utils.logout
  end

  def enroll_monitoree_and_edit(user_label, existing_monitoree_label, new_monitoree_label)
    existing_monitoree = MONITOREES[existing_monitoree_label]
    new_monitoree = MONITOREES[new_monitoree_label]
    @@system_test_utils.login(user_label)
    click_on 'Enroll New Monitoree'
    @@monitoree_enrollment_form.populate_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_form.edit_monitoree_info(new_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(new_monitoree)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(new_monitoree)
    visit '/'
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(new_monitoree)
    @@system_test_utils.logout
  end

  def enroll_monitoree_and_cancel(user_label, monitoree_label, is_epi=false)
    monitoree = MONITOREES[monitoree_label]
    @@system_test_utils.login(user_label)
    click_link 'Enroll New Monitoree'
    @@monitoree_enrollment_form.populate_monitoree_info(monitoree)
    click_on 'Cancel'
    @@system_test_utils.wait_for_pop_up_alert
    page.driver.browser.switch_to.alert.dismiss
    @@system_test_utils.wait_for_pop_up_alert
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
    click_on 'Cancel'
    @@system_test_utils.wait_for_pop_up_alert
    page.driver.browser.switch_to.alert.accept
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_not_on_dashboard(monitoree, is_epi)
    @@system_test_utils.logout
  end

  def verify_form_data_after_navigation(user_label, monitoree_label)
    @@system_test_utils.login(user_label)
    @@monitoree_enrollment_form_verifier.verify_form_data_after_navigation(MONITOREES[monitoree_label])
    @@system_test_utils.logout
  end

  def verify_input_validation(user_label, monitoree_label)
    @@system_test_utils.login(user_label)
    @@monitoree_enrollment_form_validator.verify_enrollment_input_validation(MONITOREES[monitoree_label])
    @@system_test_utils.logout
  end

  def view_enrollment_analytics(user_label)
    jurisdiction_id = @@system_test_utils.login(user_label)
    click_on 'Analytics'
    @@monitoree_enrollment_dashboard_verifier.verify_enrollment_analytics(jurisdiction_id)
    @@system_test_utils.logout
  end
end