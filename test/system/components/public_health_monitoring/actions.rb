require "application_system_test_case"

require_relative "../../lib/system_test_utils"

class PublicHealthMonitoringActions < ApplicationSystemTestCase

  @@system_test_utils = SystemTestUtils.new(nil)

  def update_monitoring_status(monitoring_status, status_change_reason, reasoning)
    if monitoring_status != find("#monitoring_status")["value"]
      select monitoring_status, from: "monitoring_status"
      @@system_test_utils.wait_for_modal_animation
      select status_change_reason, from: "monitoring_status_option"
      fill_in "reasoning", with: reasoning
      click_on "Submit"
    end
  end

  def update_exposure_risk_assessment(exposure_risk_assessment, reasoning)
    if exposure_risk_assessment != find("#exposure_risk_assessment")["value"]
      select exposure_risk_assessment, from: "exposure_risk_assessment"
      @@system_test_utils.wait_for_modal_animation
      fill_in "reasoning", with: reasoning
      click_on "Submit"
    end
  end

  def update_monitoring_plan(monitoring_plan, reasoning)
    if monitoring_plan != find("#monitoring_plan")["value"]
      select monitoring_plan, from: "monitoring_plan"
      @@system_test_utils.wait_for_modal_animation
      fill_in "reasoning", with: reasoning
      click_on "Submit"
    end
  end

  def update_jurisdiction(jurisdiction, reasoning)
    fill_in "jurisdictionList", with: jurisdiction
    click_on "Change Jurisdiction"
    @@system_test_utils.wait_for_modal_animation
    fill_in "reasoning", with: reasoning
    click_on "Submit"
  end

end