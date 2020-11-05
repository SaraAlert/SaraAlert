# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCaseMonitoree'

require_relative 'assessment/form'
require_relative '../../lib/system_test_utils'

class MonitoreeTest < ApplicationSystemTestCase
  @@assessment_form = AssessmentForm.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'monitoree complete assessments with new link' do
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(1), 'assessment_1', true)
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(2), 'assessment_2', true)
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(3), 'assessment_3', true)
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(4), 'assessment_4', true)
  end

  test 'monitoree complete assessments with new link (without initials age) ' do
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(1), 'assessment_1', false)
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(2), 'assessment_2', false)
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(3), 'assessment_3', false)
    @@assessment_form.complete_assessment_new_link(nil, Patient.find(4), 'assessment_4', false)
  end

  test 'monitoree complete assessments with old link' do
    @@assessment_form.complete_assessment_old_link(nil, Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment_old_link(nil, Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment_old_link(nil, Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment_old_link(nil, Patient.find(4), 'assessment_4')
  end

  test 'epi complete assessments as logged in user' do
    @@assessment_form.complete_assessment('usa_epi', Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment('usa_epi', Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment('usa_epi', Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment('usa_epi', Patient.find(4), 'assessment_4')
  end

  test 'epi complete assessments as logged in user with new link' do
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(1), 'assessment_1', true)
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(2), 'assessment_2', true)
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(3), 'assessment_3', true)
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(4), 'assessment_4', true)
  end

  test 'epi complete assessments as logged in user with new link (without initials age)' do
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(1), 'assessment_1', false)
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(2), 'assessment_2', false)
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(3), 'assessment_3', false)
    @@assessment_form.complete_assessment_new_link('usa_epi', Patient.find(4), 'assessment_4', false)
  end

  test 'epi complete assessments as logged in user with old link' do
    @@assessment_form.complete_assessment_old_link('usa_epi', Patient.find(1), 'assessment_1')
    @@assessment_form.complete_assessment_old_link('usa_epi', Patient.find(2), 'assessment_2')
    @@assessment_form.complete_assessment_old_link('usa_epi', Patient.find(3), 'assessment_3')
    @@assessment_form.complete_assessment_old_link('usa_epi', Patient.find(4), 'assessment_4')
  end

  test 'monitoree should not be able to submit assessment if already reported' do
    @@assessment_form.complete_multiple_assessments('usa_epi', Patient.find(1), 'assessment_1', false)
  end

  test 'logged in user should be able to submit assessment even if already reported' do
    @@assessment_form.complete_multiple_assessments('usa_epi', Patient.find(1), 'assessment_1', true)
  end

  test 'visit invalid link as monitoree' do
    @@assessment_form.visit_invalid_link(nil)
  end

  test 'visit invalid link as logged in user' do
    @@assessment_form.visit_invalid_link('usa_epi')
  end
end
