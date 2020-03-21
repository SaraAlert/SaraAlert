# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'components/assessment/form'
require_relative 'lib/system_test_utils'

class MonitoreeTest < ApplicationSystemTestCase
  @@assessment_form = AssessmentForm.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  ASSESSMENTS = @@system_test_utils.get_assessments

  test 'complete assessments' do
    @@system_test_utils.login('usa_epi')
    @@assessment_form.complete_assessment(ASSESSMENTS['assessment_1'])
    @@assessment_form.complete_assessment(ASSESSMENTS['assessment_2'])
    @@assessment_form.complete_assessment(ASSESSMENTS['assessment_3'])
    @@assessment_form.complete_assessment(ASSESSMENTS['assessment_4'])
  end
end
