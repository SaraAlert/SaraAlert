# frozen_string_literal: true

require 'mobile_application_system_test_case'

require_relative 'lib/assessment/form'
require_relative 'lib/system_test_utils'

class MonitoreeTestMobile < MobileApplicationSystemTestCase
  @@assessment_form = AssessmentForm.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  ASSESSMENTS = @@system_test_utils.get_assessments

  test 'complete assessments' do
    @@system_test_utils.login('usa_epi')
    @@assessment_form.complete_assessment(Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment(Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment(Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment(Patient.find(4), 'assessment_4')
  end
end
