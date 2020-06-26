# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'form_verifier'
require_relative '../../../lib/system_test_utils'

class AssessmentForm < ApplicationSystemTestCase
  @@assessment_form_verifier = AssessmentFormVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  PATIENTS = @@system_test_utils.patients
  ASSESSMENTS = @@system_test_utils.assessments

  def complete_assessment(patient, assessment_label)
    visit "/patients/#{patient.submission_token}/assessments/new"
    submit_assessment(ASSESSMENTS[assessment_label]['symptoms'])
    err_msg = @@system_test_utils.get_err_msg('Monitoree assessment', 'submission message', 'existent')
    assert page.has_content?('Thank You For Completing Your Self Report'), err_msg
    @@assessment_form_verifier.verify_assessment(patient, ASSESSMENTS[assessment_label])
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
