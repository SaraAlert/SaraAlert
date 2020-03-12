# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../assessment/form'
require_relative '../../lib/system_test_utils'

class PublicHealthMonitoringReports < ApplicationSystemTestCase
  @@assessment_form = AssessmentForm.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  CONDITIONS = @@system_test_utils.get_conditions
  SYMPTOMS = @@system_test_utils.get_symptoms
  REPORTS = @@system_test_utils.get_reports

  def add_report(temperature, cough, difficulty_breathing)
    click_on '(add new)'
    @@assessment_form.populate_assessment('_idprenew', temperature, cough, difficulty_breathing)
  end

  def edit_report(patient_name, report_number, temperature, cough, difficulty_breathing)
    report = REPORTS[@@system_test_utils.get_assessment_name(patient_name, report_number)]
    search_for_report(report['created_at'])
    click_on 'Edit'
    @@system_test_utils.wait_for_modal_animation
    @@assessment_form.populate_assessment('_idpre' + report['id'].to_s, temperature, cough, difficulty_breathing)
    page.driver.browser.switch_to.alert.accept
    ## also test rejecting the alert
  end

  def mark_all_as_reviewed(reasoning)
    click_on 'Mark All As Reviewed'
    @@system_test_utils.wait_for_modal_animation
    fill_in 'reasoning', with: reasoning
    click_on 'Submit'
  end

  def search_for_report(query)
    fill_in 'Search:', with: query
  end

  def verify_reports(patient_name, report_numbers)
    report_numbers.each { |report_number| 
      verify_report(patient_name, report_number)
    }
  end

  def verify_report(patient_name, report_number)
    assessment_name = @@system_test_utils.get_assessment_name(patient_name, report_number)
    report = REPORTS[assessment_name]
    search_for_report(@@system_test_utils.trim_ms_from_date(report['created_at']))
    assert_selector 'td', text: report['who_reported']
    assert_selector 'td', text: SYMPTOMS[assessment_name + '_temperature']['float_value']
    assert_selector 'td', text: SYMPTOMS[assessment_name + '_cough']['bool_value'] ? 'Yes' : 'No'
    assert_selector 'td', text: SYMPTOMS[assessment_name + '_difficulty_breathing']['bool_value'] ? 'Yes' : 'No'
    assert_selector 'td', text: report['symptomatic'] ? 'Yes' : 'No'
  end

  def verify_new_report(epi, temperature, cough, difficulty_breathing)
    search_for_report(epi['email'])
    assert_selector 'td', text: epi['email']
    assert_selector 'td', text: temperature
    assert_selector 'td', text: cough ? 'Yes' : 'No'
    assert_selector 'td', text: difficulty_breathing ? 'Yes' : 'No'
    assert_selector 'td', text: cough || difficulty_breathing ? 'Yes' : 'No'
  end

  def search_for_report(query)
    fill_in 'Search:', with: query
  end

end
