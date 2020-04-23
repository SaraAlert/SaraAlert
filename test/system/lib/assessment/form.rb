require 'application_system_test_case'

require_relative 'form_verifier'
require_relative '../../lib/system_test_utils'

class AssessmentForm < ApplicationSystemTestCase
  @@assessment_form_verifier = AssessmentFormVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  PATIENTS = @@system_test_utils.get_patients
  ASSESSMENTS = @@system_test_utils.get_assessments
  
  def complete_assessment(patient, assessment_label)
    visit "/patients/#{patient.submission_token}/assessments/new"
    submit_assessment(ASSESSMENTS[assessment_label]['symptoms'])
    assert page.has_content?('Thank You For Completing Your Self Report'), @@system_test_utils.get_err_msg('Monitoree assessment', 'submission message', 'existent')
    @@assessment_form_verifier.verify_assessment(patient, ASSESSMENTS[assessment_label])
  end
  
  def submit_assessment(symptoms)
    symptoms.each { |symptom|
      case symptom['type']
      when 'BoolSymptom'
        find('label', text: symptom['label']).click if symptom['bool_value']
      when 'FloatSymptom'
        fill_in symptom['label'], with: symptom['float_value']
      when 'IntSymptom'
        fill_in symptom['label'], with: symptom['int_value']
      end
    }
    click_on 'Submit'
  end
end