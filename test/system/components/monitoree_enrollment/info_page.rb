require "application_system_test_case"

require_relative "../../lib/monitoree_enrollment/form_populator"
require_relative "../../lib/monitoree_enrollment/info_page_verifier"
require_relative "../../lib/system_test_utils"

class MonitoreeEnrollmentInfoPage < ApplicationSystemTestCase

  @@monitoree_enrollment_form_populator = MonitoreeEnrollmentFormPopulator.new(nil)
  @@monitoree_enrollment_info_page_verifier = MonitoreeEnrollmentInfoPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def edit_data_on_review_page(monitoree)
    click_on_edit_link("Identification")
    @@monitoree_enrollment_form_populator.populate_identification(monitoree["identification"], true)
    @@system_test_utils.wait_for_enrollment_page_transition
    click_on_edit_link("Address")
    @@monitoree_enrollment_form_populator.populate_address(monitoree["address"], true)
    @@system_test_utils.wait_for_enrollment_page_transition
    click_on_edit_link("Contact Information")
    @@monitoree_enrollment_form_populator.populate_contact_info(monitoree["contact_info"], true)
    @@system_test_utils.wait_for_enrollment_page_transition
    click_on_edit_link("Arrival Information")
    @@monitoree_enrollment_form_populator.populate_arrival_info(monitoree["arrival_info"], true)
    @@system_test_utils.wait_for_enrollment_page_transition
    click_on_edit_link("Additional Planned Travel")
    @@monitoree_enrollment_form_populator.populate_additional_planned_travel(monitoree["additional_planned_travel"], true)
    @@system_test_utils.wait_for_enrollment_page_transition
    click_on_edit_link("Potential Exposure Information")
    @@monitoree_enrollment_form_populator.populate_potential_exposure_info(monitoree["potential_exposure_info"], true)
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
  end

  def click_on_edit_link(label)
    find("h5", text: label).first(:xpath, ".//..//..").click_on("Edit")
  end

end