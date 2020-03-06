require "application_system_test_case"

require_relative "info_page"
require_relative "../../lib/monitoree_enrollment/dashboard_verifier"
require_relative "../../lib/monitoree_enrollment/form_populator"
require_relative "../../lib/monitoree_enrollment/form_validator"
require_relative "../../lib/monitoree_enrollment/form_verifier"
require_relative "../../lib/monitoree_enrollment/info_page_verifier"
require_relative "../../lib/system_test_utils"

class MonitoreeEnrollmentForm < ApplicationSystemTestCase

  @@monitoree_enrollment_info_page = MonitoreeEnrollmentInfoPage.new(nil)
  @@monitoree_enrollment_dashboard_verifier = MonitoreeEnrollmentDashboardVerifier.new(nil)
  @@monitoree_enrollment_form_populator = MonitoreeEnrollmentFormPopulator.new(nil)
  @@monitoree_enrollment_form_validator = MonitoreeEnrollmentFormValidator.new(nil)
  @@monitoree_enrollment_form_verifier = MonitoreeEnrollmentFormVerifier.new(nil)
  @@monitoree_enrollment_info_page_verifier = MonitoreeEnrollmentInfoPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def enroll_monitoree(enroller, monitoree)
    @@system_test_utils.login(enroller)
    click_on "Enroll New Monitoree"
    @@monitoree_enrollment_form_populator.populate_monitoree_info(monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
    click_on "Finish"
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
    @@system_test_utils.wait_for_enrollment_submission
    click_on "Return To Dashboard"
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(monitoree)
  end

  def enroll_monitorees_in_group(enroller, existing_monitoree, new_monitoree)
    @@system_test_utils.login(enroller)
    click_link "Enroll New Monitoree"
    @@monitoree_enrollment_form_populator.populate_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    click_on "Finish and add a Group Member"
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    @@system_test_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_form_populator.populate_monitoree_info(new_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info_as_group_member(existing_monitoree, new_monitoree)
    click_on "Finish"
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info_as_group_member(existing_monitoree, new_monitoree)
    @@system_test_utils.wait_for_enrollment_submission
    click_on "Return To Dashboard"
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_as_group_member_on_dashboard(existing_monitoree, new_monitoree)
  end

  def enroll_monitoree_with_same_monitored_address_as_home(enroller, monitoree)
    @@system_test_utils.login(enroller)
    click_link "Enroll New Monitoree"
    @@monitoree_enrollment_form_populator.populate_monitoree_info_with_same_monitored_address_as_home(monitoree)
  end

  def enroll_monitoree_and_edit_info(enroller, existing_monitoree, new_monitoree)
    enroll_monitoree(enroller, existing_monitoree)
    click_on @@system_test_utils.get_dashboard_display_name(existing_monitoree)
    click_on "(click here to edit)"
    @@monitoree_enrollment_info_page.edit_data_on_review_page(new_monitoree)
    click_on "Finish"
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(new_monitoree)
    click_on "Return To Dashboard"
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(new_monitoree)
  end

  def enroll_monitoree_and_cancel(enroller, monitoree, cancel_link)
    @@system_test_utils.login(enroller)
    click_link "Enroll New Monitoree"
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

  def enroll_monitoree_and_edit_data_on_review_page(enroller, existing_monitoree, new_monitoree)
    @@system_test_utils.login(enroller)
    click_on "Enroll New Monitoree"
    @@monitoree_enrollment_form_populator.populate_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_info_page.edit_data_on_review_page(new_monitoree)
  end

  def enroll_monitoree_and_edit_data_after_submission(enroller, monitoree)
    @@system_test_utils.login(enroller)
    display_name = @patients_dashboard_component_test_helper.search_for_monitoree(monitoree)
    click_on display_name
    click_on "(click here to edit)"
    @@monitoree_enrollment_info_page.edit_data_on_review_page(monitoree)
  end

  def verify_form_data_after_navigation(enroller, monitoree)
    @@system_test_utils.login(enroller)
    @@monitoree_enrollment_form_verifier.verify_form_data_after_navigation(monitoree)
  end

  def verify_enrollment_input_validation(enroller, monitoree)
    @@system_test_utils.login(enroller)
    @@monitoree_enrollment_form_validator.verify_enrollment_input_validation(monitoree)
  end

end