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

  def add_report(assessment)
    click_on '(add new)'
    @@assessment_form.populate_assessment(assessment['symptoms'])
  end

  def edit_report(patient_name, report_number, assessment)
    report = REPORTS[@@system_test_utils.get_assessment_name(patient_name, report_number)]
    search_for_report(report['id'])
    click_on 'Edit'
    @@assessment_form.populate_assessment(assessment['symptoms'])
    page.driver.browser.switch_to.alert.accept
  end

  def edit_report_and_cancel(patient_name, report_number, assessment)
    report = REPORTS[@@system_test_utils.get_assessment_name(patient_name, report_number)]
    search_for_report(report['id'])
    click_on 'Edit'
    @@assessment_form.populate_assessment(assessment['symptoms'])
    page.driver.browser.switch_to.alert.dismiss
    assert_selector 'h4', text: 'Daily Self-Report'
    find('button', class: 'close').click
  end

  def mark_all_as_reviewed(reasoning)
    click_on 'Mark All As Reviewed'
    fill_in 'reasoning', with: reasoning
    click_on 'Submit'
  end

  def search_for_report(query)
    fill_in 'Search:', with: query
  end

  def verify_existing_reports(patient_name, report_numbers)
    report_numbers.each { |report_number|
      assessment_name = @@system_test_utils.get_assessment_name(patient_name, report_number)
      report = REPORTS[assessment_name]
      search_for_report(report['id'])
      assert_selector 'td', text: report['who_reported']
      SYMPTOMS.keys().each { |symptom_key|
        if symptom_key.include? assessment_name
          verify_symptom(SYMPTOMS[symptom_key])
        end
      }
    }
  end

  def verify_new_report(epi, assessment)
    search_for_report(epi['email'])
    assert_selector 'td', text: epi['email']
    assessment['symptoms'].each { |symptom|
      verify_symptom(symptom)
    }
  end

  def verify_symptom(symptom)
    case symptom['type']
    when 'BoolSymptom'
      ## make assertion more specific
      assert_selector 'td', text: symptom['bool_value'] ? 'Yes' : 'No'
    when 'FloatSymptom'
      assert_selector 'td', text: symptom['float_value']
    when 'IntSymptom'
      assert_selector 'td', text: symptom['int_value']
    end
  end

  def search_for_report(query)
    fill_in 'Search:', with: query
  end
end
