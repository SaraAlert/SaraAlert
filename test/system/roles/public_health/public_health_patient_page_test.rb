# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthPatientPage'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  ASSESSMENTS = @@system_test_utils.assessments

  ## Patient page

  test 'update monitoring status to not monitoring' do
    @@public_health_test_helper.update_monitoring_status('state1_epi', 'patient_2', 'non_reporting', 'closed',
                                                         'Not Monitoring', 'Completed Monitoring', 'details')
  end

  test 'update monitoring status to actively monitoring' do
    @@public_health_test_helper.update_monitoring_status('state1_epi', 'patient_5', 'closed', 'all',
                                                         'Actively Monitoring', nil, 'notes')
  end

  test 'update exposure risk assessment' do
    @@public_health_test_helper.update_exposure_risk_assessment('locals1c1_epi', 'patient_4', 'asymptomatic', 'High', 'details')
  end

  test 'update monitoring plan' do
    @@public_health_test_helper.update_monitoring_plan('locals1c2_epi', 'patient_6', 'pui', 'Daily active monitoring', 'details')
  end

  test 'update latest public health action' do
    @@public_health_test_helper.update_latest_public_health_action('state1_epi_enroller', 'patient_7', 'pui',
                                                                   'Recommended medical evaluation of symptoms', 'details')
  end

  test 'update assigned jurisdiction' do
    @@public_health_test_helper.update_assigned_jurisdiction('state2_epi', 'patient_11', 'pui', 'USA, State 2, County 4', 'details', true, true)
    @@public_health_test_helper.update_assigned_jurisdiction('state2_epi', 'patient_10', 'pui', 'USA, State 1', 'details', true, false)
  end

  test 'update assigned jurisdiction validation' do
    @@public_health_test_helper.update_assigned_jurisdiction('state2_epi', 'patient_11', 'pui', 'Fake Jurisdiction', 'details', false, true)
  end

  test 'update assigned user' do
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_2', 'all', '9', 'reasoning', true, true)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_2', 'all', '', 'reasoning', true, true)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '1444', 'reason', true, true)
  end

  test 'update assigned user validation' do
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_2', 'all', '', 'reason', false, false)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '1444', '', false, false)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '0', 'reason', false, true)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '10000', '', false, true)
    @@public_health_test_helper.update_assigned_user('state1_epi_enroller', 'patient_4', 'all', '-8', 'reason', false, true)
    @@public_health_test_helper.update_assigned_user('state1_epi_enroller', 'patient_2', 'all', '1.5', '', false, true)
    @@public_health_test_helper.update_assigned_user('state1_epi_enroller', 'patient_2', 'all', 'not valid', 'reason', false, true)
  end

  test 'add report' do
    @@public_health_test_helper.add_report('locals1c1_epi', 'patient_4', 'asymptomatic', ASSESSMENTS['assessment_1'])
  end

  test 'edit report' do
    @@public_health_test_helper.edit_report('locals2c4_epi', 'patient_10', 'pui', 1017, ASSESSMENTS['assessment_2'])
  end

  test 'add note to report' do
    @@public_health_test_helper.add_note_to_report('state2_epi', 'patient_10', 'pui', 1016, 'note')
  end

  test 'mark all reports as reviewed' do
    @@public_health_test_helper.mark_all_as_reviewed('state1_epi_enroller', 'patient_5', 'closed', 'comment')
  end

  test 'pause notifications' do
    @@public_health_test_helper.pause_notifications('state1_epi', 'patient_2', 'non_reporting')
    @@public_health_test_helper.pause_notifications('state1_epi', 'patient_2', 'non_reporting')
  end

  test 'add comment' do
    @@public_health_test_helper.add_comment('locals2c3_epi', 'patient_11', 'pui', 'comment')
  end
end
