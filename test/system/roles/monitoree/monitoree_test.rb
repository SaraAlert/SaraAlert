# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'assessment/form'
require_relative '../../lib/system_test_utils'

class MonitoreeTest < ApplicationSystemTestCase
  @@monitoree_assessment_form = MonitoreeAssessmentForm.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'complete assessments' do
    @@system_test_utils.login('usa_epi')
    @@monitoree_assessment_form.complete_assessment(Patient.find(1), 'assessment_1')
    @@monitoree_assessment_form.complete_assessment(Patient.find(2), 'assessment_2')
    @@monitoree_assessment_form.complete_assessment(Patient.find(3), 'assessment_3')
    @@monitoree_assessment_form.complete_assessment(Patient.find(4), 'assessment_4')
  end
end
