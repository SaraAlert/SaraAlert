# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'info_page'
require_relative '../../lib/monitoree_enrollment/dashboard_verifier'
require_relative '../../lib/monitoree_enrollment/form_populator'
require_relative '../../lib/monitoree_enrollment/form_validator'
require_relative '../../lib/monitoree_enrollment/form_verifier'
require_relative '../../lib/monitoree_enrollment/info_page_verifier'
require_relative '../../lib/system_test_utils'

class MonitoreeEnrollmentForm < ApplicationSystemTestCase
  @@monitoree_enrollment_info_page = MonitoreeEnrollmentInfoPage.new(nil)
  @@monitoree_enrollment_dashboard_verifier = MonitoreeEnrollmentDashboardVerifier.new(nil)
  @@monitoree_enrollment_form_populator = MonitoreeEnrollmentFormPopulator.new(nil)
  @@monitoree_enrollment_form_validator = MonitoreeEnrollmentFormValidator.new(nil)
  @@monitoree_enrollment_form_verifier = MonitoreeEnrollmentFormVerifier.new(nil)
  @@monitoree_enrollment_info_page_verifier = MonitoreeEnrollmentInfoPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  MONITOREES = @@system_test_utils.get_monitorees

  def enroll_monitoree(user_name, monitoree_name, isEpi=false)
    monitoree = MONITOREES[monitoree_name]
    @@system_test_utils.login(user_name)
    click_on 'Enroll New Monitoree'
    @@monitoree_enrollment_form_populator.populate_monitoree_info(monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree, isEpi)
    click_on 'Return to Exposure Dashboard'
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(monitoree, isEpi)
  end

  def enroll_monitorees_in_group(user_name, existing_monitoree_name, new_monitoree_name, isEpi=false)
    existing_monitoree = MONITOREES[existing_monitoree_name]
    new_monitoree = MONITOREES[new_monitoree_name]
    @@system_test_utils.login(user_name)
    click_link 'Enroll New Monitoree'
    @@monitoree_enrollment_form_populator.populate_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    click_on 'Finish and Add a Household Member'
    click_on 'Continue'
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    @@system_test_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_form_populator.populate_monitoree_info(new_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info_as_group_member(existing_monitoree, new_monitoree)
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info_as_group_member(existing_monitoree, new_monitoree, isEpi)
    click_on 'Return to Exposure Dashboard'
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_as_group_member_on_dashboard(existing_monitoree, new_monitoree, isEpi)
  end

  def enroll_monitoree_with_same_monitored_address_as_home(user_name, monitoree_name)
    @@system_test_utils.login(user_name)
    click_link 'Enroll New Monitoree'
    @@monitoree_enrollment_form_populator.populate_monitoree_info_with_same_monitored_address_as_home(MONITOREES[monitoree_name])
  end

  def enroll_monitoree_and_edit_info(user_name, existing_monitoree_name, new_monitoree_name)
    enroll_monitoree(user_name, existing_monitoree_name)
    click_on @@system_test_utils.get_dashboard_display_name(MONITOREES[existing_monitoree_name])
    click_on '(edit details)'
    @@monitoree_enrollment_info_page.edit_data_on_review_page(MONITOREES[new_monitoree_name])
    click_on 'Finish'
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(MONITOREES[new_monitoree_name])
    click_on 'Return to Exposure Dashboard'
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(MONITOREES[new_monitoree_name])
  end

  def enroll_monitoree_and_cancel(user_name, monitoree_name, cancel_link)
    monitoree = MONITOREES[monitoree_name]
    @@system_test_utils.login(user_name)
    click_link 'Enroll New Monitoree'
    @@monitoree_enrollment_form_populator.populate_monitoree_info(monitoree)
    click_on cancel_link
    @@system_test_utils.wait_for_pop_up_alert
    page.driver.browser.switch_to.alert.dismiss
    @@system_test_utils.wait_for_pop_up_alert
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
    click_on cancel_link
    @@system_test_utils.wait_for_pop_up_alert
    page.driver.browser.switch_to.alert.accept
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_not_on_dashboard(monitoree)
  end

  def enroll_monitoree_and_edit_data_on_review_page(user_name, existing_monitoree_name, new_monitoree_name)
    @@system_test_utils.login(user_name)
    click_on 'Enroll New Monitoree'
    @@monitoree_enrollment_form_populator.populate_monitoree_info(MONITOREES[existing_monitoree_name])
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(MONITOREES[existing_monitoree_name])
    @@monitoree_enrollment_info_page.edit_data_on_review_page(MONITOREES[new_monitoree_name])
  end

  def enroll_monitoree_and_edit_data_after_submission(user_name, monitoree_name)
    @@system_test_utils.login(user_name)
    display_name = @patients_dashboard_component_test_helper.search_for_monitoree(MONITOREES[monitoree_name])
    click_on display_name
    click_on '(edit details)'
    @@monitoree_enrollment_info_page.edit_data_on_review_page(MONITOREES[monitoree_name])
  end

  def verify_form_data_after_navigation(user_name, monitoree_name)
    @@system_test_utils.login(user_name)
    @@monitoree_enrollment_form_verifier.verify_form_data_after_navigation(MONITOREES[monitoree_name])
  end

  def verify_enrollment_input_validation(user_name, monitoree_name)
    @@system_test_utils.login(user_name)
    @@monitoree_enrollment_form_validator.verify_enrollment_input_validation(MONITOREES[monitoree_name])
  end
end
