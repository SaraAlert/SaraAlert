# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCaseMonitoree'

require_relative 'assessment/form'
require_relative '../../lib/system_test_utils'

class MonitoreeTest < ApplicationSystemTestCase
  @@assessment_form = AssessmentForm.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'complete assessments' do
    @@assessment_form.complete_assessment(nil, Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment(nil, Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment(nil, Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment(nil, Patient.find(4), 'assessment_4')
  end

  test 'complete assessments with new link' do
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(4), 'assessment_4')
  end

  test 'complete assessments with old link' do
    @@assessment_form.complete_assessment_old_link(nil, Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment_old_link(nil, Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment_old_link(nil, Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment_old_link(nil, Patient.find(4), 'assessment_4')
  end

  test 'complete assessments as logged in user' do
    @@assessment_form.complete_assessment('usa_epi', Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment('usa_epi', Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment('usa_epi', Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment('usa_epi', Patient.find(4), 'assessment_4')
  end

  test 'complete assessments as logged in user with new link' do
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(4), 'assessment_4')
  end

  test 'complete assessments as logged in user with old link' do
    @@assessment_form.complete_assessment_old_link('usa_epi', Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment_old_link('usa_epi', Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment_old_link('usa_epi', Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment_old_link('usa_epi', Patient.find(4), 'assessment_4')
  end

  test 'already completed assessment' do
    patient = Patient.find(9)
    @@assessment_form.complete_assessment_new_link('usa_epi', patient, 'assessment_1')
    @@system_test_utils.login('usa_epi')
    visit "/r/#{patient.submission_token}/#{patient.jurisdiction.unique_identifier}/en/#{patient.initials}"
    assert page.has_content?('It appears you have already submitted your report. Please wait before reporting again.')
    visit "/patients/#{patient.submission_token}/assessments/new"
    assert page.has_content?('It appears you have already submitted your report. Please wait before reporting again.')
    visit "/report/patients/#{patient.submission_token}/en/#{patient.jurisdiction.unique_identifier}"
    assert page.has_content?('It appears you have already submitted your report. Please wait before reporting again.')
  end

  test 'visit invalid link' do
    visit '/r/invalid/link/en/initials'
    assert page.has_content?('It appears that this assessment link is invalid.')
    visit '/patients/invalid_submission_token/assessments/new'
    assert page.has_content?('It appears that this assessment link is invalid.')
    visit '/report/patients/invalid_submission_token/en/invalid_unique_identifier'
    assert page.has_content?('It appears that this assessment link is invalid.')
  end
end
