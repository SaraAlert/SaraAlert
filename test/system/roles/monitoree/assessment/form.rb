# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'form_verifier'
require_relative '../../../lib/system_test_utils'

class AssessmentForm < ApplicationSystemTestCase
  @@assessment_form_verifier = AssessmentFormVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  PATIENTS = @@system_test_utils.patients
  ASSESSMENTS = @@system_test_utils.assessments

  def complete_assessment(user_label, patient, assessment_label)
    @@system_test_utils.login(user_label) unless user_label.nil?
    visit "/patients/#{patient.submission_token}/assessments/new"
    submit_assessment(ASSESSMENTS[assessment_label]['symptoms'])
    err_msg = @@system_test_utils.get_err_msg('Monitoree assessment', 'submission message', 'existent')
    assert page.has_content?('Thank You For Completing Your Self Report'), err_msg
    @@assessment_form_verifier.verify_assessment(patient, ASSESSMENTS[assessment_label], patient.submission_token) unless user_label.nil?
    @@system_test_utils.logout unless user_label.nil?
  end

  def complete_assessment_new_link(user_label, patient, assessment_label, initials_age)
    @@system_test_utils.login(user_label) unless user_label.nil?
    visit "/r/#{patient.submission_token}/#{patient.jurisdiction.unique_identifier}/en/#{initials_age ? patient.initials_age : ''}"
    submit_assessment(ASSESSMENTS[assessment_label]['symptoms'])
    err_msg = @@system_test_utils.get_err_msg('Monitoree assessment', 'submission message', 'existent')
    assert page.has_content?('Thank You For Completing Your Self Report'), err_msg
    @@assessment_form_verifier.verify_assessment(patient, ASSESSMENTS[assessment_label], patient.submission_token) unless user_label.nil?
    @@system_test_utils.logout unless user_label.nil?
  end

  def complete_assessment_old_link(user_label, patient, assessment_label)
    @@system_test_utils.login(user_label) unless user_label.nil?
    old_submission_token = PatientLookup.find_by(new_submission_token: patient.submission_token).old_submission_token
    old_unique_identifier = JurisdictionLookup.find_by(new_unique_identifier: patient.jurisdiction.unique_identifier).old_unique_identifier
    visit "/report/patients/#{old_submission_token}/en/#{old_unique_identifier}"
    submit_assessment(ASSESSMENTS[assessment_label]['symptoms'])
    err_msg = @@system_test_utils.get_err_msg('Monitoree assessment', 'submission message', 'existent')
    assert page.has_content?('Thank You For Completing Your Self Report'), err_msg
    @@assessment_form_verifier.verify_assessment(patient, ASSESSMENTS[assessment_label], old_submission_token) unless user_label.nil?
    @@system_test_utils.logout unless user_label.nil?
  end

  def complete_multiple_assessments(user_label, patient, assessment_label, logged_in)
    complete_assessment_new_link(user_label, patient, assessment_label, patient.initials_age)
    complete_assessment_old_link(user_label, patient, assessment_label)
    @@system_test_utils.login(user_label) if logged_in
    old_submission_token = PatientLookup.find_by(new_submission_token: patient.submission_token).old_submission_token
    old_unique_identifier = JurisdictionLookup.find_by(new_unique_identifier: patient.jurisdiction.unique_identifier).old_unique_identifier
    [
      "/patients/#{patient.submission_token}/assessments/new",
      "/r/#{patient.submission_token}/#{patient.jurisdiction.unique_identifier}/en",
      "/r/#{patient.submission_token}/#{patient.jurisdiction.unique_identifier}/en/#{patient.initials_age}",
      "/report/patients/#{old_submission_token}/en/#{old_unique_identifier}"
    ].each do |assessment_link|
      visit assessment_link
      message = 'It appears you have already submitted your report. Please wait before reporting again.'
      assert page.has_content?(message) unless logged_in
      assert page.has_no_content?(message) if logged_in
    end
  end

  def visit_invalid_link(user_label)
    @@system_test_utils.login(user_label) unless user_label.nil?
    [
      '/r/invalid/link/en/initials',
      '/patients/invalid_submission_token/assessments/new',
      '/report/patients/invalid_submission_token/en/invalid_unique_identifier'
    ].each do |invalid_link|
      visit invalid_link
      assert page.has_content?('It appears that this assessment link is invalid.')
    end
  end

  def submit_assessment(symptoms)
    symptoms.each do |symptom|
      case symptom['type']
      when 'BoolSymptom'
        find('label', text: symptom['label']).click if symptom['bool_value']
      when 'FloatSymptom'
        fill_in symptom['label'], with: symptom['float_value']
      when 'IntegerSymptom'
        fill_in symptom['label'], with: symptom['int_value']
      end
    end
    click_on 'Submit'
  end
end
