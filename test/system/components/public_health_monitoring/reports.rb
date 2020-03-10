# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../../lib/system_test_utils'

class PublicHealthMonitoringReports < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def add_report(temperature, cough, difficulty_breathing)
    click_on '(add new)'
    populate_report('new', temperature, cough, difficulty_breathing)
  end

  def edit_report(report, temperature, cough, difficulty_breathing)
    search_for_report(report['created_at'])
    click_on 'Edit'
    populate_report(report['id'].to_s, temperature, cough, difficulty_breathing)
    page.driver.browser.switch_to.alert.accept
    ## also test rejecting the alert
  end

  def clear_all_reports(reasoning)
    click_on 'Clear All Reports'
    @@system_test_utils.wait_for_modal_animation
    fill_in 'reasoning', with: reasoning
    click_on 'Submit'
  end

  def search_for_report(query)
    fill_in 'Search:', with: query
  end

  def populate_report(report_id, temperature, cough, difficulty_breathing)
    @@system_test_utils.wait_for_modal_animation
    fill_in 'temperature_idpre' + report_id, with: temperature
    if cough || difficulty_breathing
      select 'Yes', from: 'experiencing_symptoms_idpre' + report_id
      click_on 'Continue'
      @@system_test_utils.wait_for_checkbox_animation
      find('label', text: 'Cough').click if cough
      find('label', text: 'Difficulty Breathing').click if difficulty_breathing
    else
      select 'No', from: 'experiencing_symptoms_idpre' + report_id
    end
    click_on 'Submit'
  end
end
