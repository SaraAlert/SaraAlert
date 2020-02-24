require "application_system_test_case"

require_relative "info_page"
require_relative "../../lib/monitoree_enrollment/dashboard_verifier"
require_relative "../../lib/monitoree_enrollment/form_populator"
require_relative "../../lib/monitoree_enrollment/form_validator"
require_relative "../../lib/monitoree_enrollment/form_verifier"
require_relative "../../lib/monitoree_enrollment/info_page_verifier"
require_relative "../../lib/monitoree_enrollment/utils"

class MonitoreeEnrollmentForm < ApplicationSystemTestCase

  @@monitoree_enrollment_info_page = MonitoreeEnrollmentInfoPage.new(nil)
  @@monitoree_enrollment_dashboard_verifier = MonitoreeEnrollmentDashboardVerifier.new(nil)
  @@monitoree_enrollment_form_populator = MonitoreeEnrollmentFormPopulator.new(nil)
  @@monitoree_enrollment_form_validator = MonitoreeEnrollmentFormValidator.new(nil)
  @@monitoree_enrollment_form_verifier = MonitoreeEnrollmentFormVerifier.new(nil)
  @@monitoree_enrollment_info_page_verifier = MonitoreeEnrollmentInfoPageVerifier.new(nil)
  @@monitoree_enrollment_utils = MonitoreeEnrollmentUtils.new(nil)

  def enroll_monitoree(enroller, redirect_url, monitoree)
    @@monitoree_enrollment_utils.login(enroller, redirect_url)
    click_on "Enroll New Monitoree"
    @@monitoree_enrollment_form_populator.populate_monitoree_info(monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
    click_on "Finish"
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
    @@monitoree_enrollment_utils.wait_for_enrollment_submission
    click_on "Return To Dashboard"
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(monitoree, redirect_url)
  end

  def enroll_monitorees_in_group(enroller, redirect_url, existing_monitoree, new_monitoree)
    @@monitoree_enrollment_utils.login(enroller, redirect_url)
    click_link "Enroll New Monitoree"
    @@monitoree_enrollment_form_populator.populate_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    click_on "Finish and add a Group Member"
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_utils.wait_for_enrollment_submission
    @@monitoree_enrollment_form_populator.populate_monitoree_info(new_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info_as_group_member(existing_monitoree, new_monitoree)
    click_on "Finish"
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info_as_group_member(existing_monitoree, new_monitoree)
    @@monitoree_enrollment_utils.wait_for_enrollment_submission
    click_on "Return To Dashboard"
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_as_group_member_on_dashboard(existing_monitoree, new_monitoree, redirect_url)
  end

  def enroll_monitoree_with_same_monitored_address_as_home(enroller, redirect_url, monitoree)
    @@monitoree_enrollment_utils.login(enroller, redirect_url)
    click_link "Enroll New Monitoree"
    @@monitoree_enrollment_form_populator.populate_monitoree_info_with_same_monitored_address_as_home(monitoree)
  end

  def enroll_monitoree_and_edit_info(enroller, redirect_url, existing_monitoree, new_monitoree)
    enroll_monitoree(enroller, redirect_url, existing_monitoree)
    click_on existing_monitoree["identification"]["last_name"] + ", " + existing_monitoree["identification"]["first_name"]
    click_on "(click here to edit)"
    @@monitoree_enrollment_info_page.edit_data_on_review_page(new_monitoree)
    click_on "Finish"
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(new_monitoree)
    click_on "Return To Dashboard"
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(new_monitoree, redirect_url)
  end

  def enroll_monitoree_and_cancel(enroller, redirect_url, monitoree, cancel_link)
    @@monitoree_enrollment_utils.login(enroller, redirect_url)
    click_link "Enroll New Monitoree"
    @@monitoree_enrollment_form_populator.populate_monitoree_info(monitoree)
    click_on cancel_link
    @@monitoree_enrollment_utils.wait_for_pop_up_alert
    page.driver.browser.switch_to.alert.dismiss
    @@monitoree_enrollment_utils.wait_for_pop_up_alert
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
    click_on cancel_link
    @@monitoree_enrollment_utils.wait_for_pop_up_alert
    page.driver.browser.switch_to.alert.accept
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_not_on_dashboard(monitoree)
  end

  def enroll_monitoree_and_edit_data_on_review_page(enroller, redirect_url, existing_monitoree, new_monitoree)
    @@monitoree_enrollment_utils.login(enroller, redirect_url)
    click_on "Enroll New Monitoree"
    @@monitoree_enrollment_form_populator.populate_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    @@monitoree_enrollment_info_page.edit_data_on_review_page(new_monitoree)
  end

  def enroll_monitoree_and_edit_data_after_submission(enroller, redirect_url, monitoree)
    @@monitoree_enrollment_utils.login(enroller, redirect_url)
    display_name = @patients_dashboard_component_test_helper.search_for_monitoree(monitoree)
    click_on display_name
    click_on "(click here to edit)"
    @@monitoree_enrollment_info_page.edit_data_on_review_page(MONITOREES["monitoree_6"])
  end

  def verify_form_data_after_navigation(enroller, redirect_url, monitoree)
    @@monitoree_enrollment_utils.login(enroller, redirect_url)
    @@monitoree_enrollment_form_verifier.verify_form_data_after_navigation(monitoree)
  end

  def verify_enrollment_input_validation(enroller, redirect_url, monitoree)
    @@monitoree_enrollment_utils.login(enroller, redirect_url)
    @@monitoree_enrollment_form_validator.verify_enrollment_input_validation(monitoree)
  end

end