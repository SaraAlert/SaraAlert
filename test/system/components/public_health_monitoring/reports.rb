require "application_system_test_case"

require_relative "../../lib/public_health_monitoring/utils"

class PublicHealthMonitoringReports < ApplicationSystemTestCase

  @@public_health_monitoring_utils = PublicHealthMonitoringUtils.new(nil)
  
  def add_report(temperature, cough, difficulty_breathing)
    click_on "(add new)"
    populate_report("new", temperature, cough, difficulty_breathing)
  end

  def edit_report(query, report_id, temperature, cough, difficulty_breathing)
    search_for_report(query)
    click_on "Edit"
    populate_report(report_id, temperature, cough, difficulty_breathing)
  end

  def search_for_report(query)
    fill_in "Search:", with: query
  end

  def clear_all_reports(reasoning)
    click_on "Clear All Reports"
    @@public_health_monitoring_utils.wait_for_modal_animation
    fill_in "reasoning", with: reasoning
    click_on "Submit"
  end

  def populate_report(report_id, temperature, cough, difficulty_breathing)
    @@public_health_monitoring_utils.wait_for_modal_animation
    fill_in "temperature_idpre" + report_id, with: temperature
    if cough or difficulty_breathing
      select "Yes", from: "experiencing_symptoms_idpre" + report_id
      click_on "Continue"
      @@public_health_monitoring_utils.wait_for_checkbox_animation
      find("label", text: "Cough").click if cough
      find("label", text: "Difficulty Breathing").click if difficulty_breathing
    else
      select "No", from: "experiencing_symptoms_idpre" + report_id
    end
    click_on "Submit"
  end

end