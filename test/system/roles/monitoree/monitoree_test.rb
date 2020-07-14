# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCaseMonitoree'

require_relative 'assessment/form'
require_relative '../../lib/system_test_utils'

class MonitoreeTest < ApplicationSystemTestCase
  @@assessment_form = AssessmentForm.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'complete assessments' do
    @@system_test_utils.login('usa_epi')
    @@assessment_form.complete_assessment(Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment(Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment(Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment(Patient.find(4), 'assessment_4')
  end
end
