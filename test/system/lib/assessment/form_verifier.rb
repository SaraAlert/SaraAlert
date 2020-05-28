require 'application_system_test_case'

require_relative '../../lib/system_test_utils'

class AssessmentFormVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_assessment(patient, assessment)
    saved_assessment = Assessment.where(patient_id: patient.id).joins(:patient).order(created_at: :desc).first
    saved_condition = Condition.where(assessment_id: saved_assessment['id']).first
    assessment['symptoms'].each { |symptom|
      saved_symptom = Symptom.where(condition_id: saved_condition['id'], label: symptom['label']).first
      case symptom['type']
      when 'BoolSymptom'
        assert_equal(symptom['bool_value'], saved_symptom['bool_value'], @@system_test_utils.get_err_msg('Monitoree assessment', symptom['label'], symptom['bool_value']))
      when 'FloatSymptom'
        assert_equal(symptom['float_value'], saved_symptom['float_value'], @@system_test_utils.get_err_msg('Monitoree assessment', symptom['label'], symptom['float_value']))
      when 'IntegerSymptom'
        assert_equal(symptom['int_value'], saved_symptom['int_value'], @@system_test_utils.get_err_msg('Monitoree assessment', symptom['label'], symptom['int_value']))
      end
    }
  end
end