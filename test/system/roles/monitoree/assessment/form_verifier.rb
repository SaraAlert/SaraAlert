# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../../../lib/system_test_utils'

class AssessmentFormVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_assessment(patient, assessment, submission_token)
    sleep(0.1) # wait for assessment to be saved
    assert AssessmentReceipt.where('submission_token = ? AND created_at > ?', submission_token, 5.seconds.ago).any?, 'Missing assessment receipt'
    saved_assessment = Assessment.where('patient_id = ? AND assessments.created_at > ?', patient.id, 5.seconds.ago).joins(:patient).first
    assert saved_assessment.present?, @@system_test_utils.get_err_msg('Monitoree assessment', 'assessment', 'existent')
    saved_condition = Condition.where(assessment_id: saved_assessment['id']).first
    assessment['symptoms'].each do |symptom|
      saved_symptom = Symptom.where(condition_id: saved_condition['id'], label: symptom['label']).first
      case symptom['type']
      when 'BoolSymptom'
        err_msg = @@system_test_utils.get_err_msg('Monitoree assessment', symptom['label'], symptom['bool_value'])
        assert_equal symptom['bool_value'], saved_symptom['bool_value'], err_msg
      when 'FloatSymptom'
        err_msg = @@system_test_utils.get_err_msg('Monitoree assessment', symptom['label'], symptom['float_value'])
        assert_equal symptom['float_value'], saved_symptom['float_value'], err_msg
      when 'IntegerSymptom'
        err_msg = @@system_test_utils.get_err_msg('Monitoree assessment', symptom['label'], symptom['int_value'])
        assert_equal symptom['int_value'], saved_symptom['int_value'], err_msg
      end
    end
  end
end
