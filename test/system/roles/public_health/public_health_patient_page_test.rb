# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthPatientPage'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthPatientPageTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'verify patient details and reports' do
    @@public_health_test_helper.view_patients_details_and_reports('state1_epi')
    @@public_health_test_helper.view_patients_details_and_reports('state2_epi')
  end

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
    @@public_health_test_helper.update_assigned_jurisdiction('state2_epi',
                                                             'patient_11',
                                                             'pui',
                                                             'USA, State 2, County 4',
                                                             'details',
                                                             valid_jurisdiction: true,
                                                             under_hierarchy: true)
    @@public_health_test_helper.update_assigned_jurisdiction('state2_epi',
                                                             'patient_10',
                                                             'pui',
                                                             'USA, State 1',
                                                             'details',
                                                             valid_jurisdiction: true,
                                                             under_hierarchy: false)
  end

  test 'update assigned jurisdiction validation' do
    @@public_health_test_helper.update_assigned_jurisdiction('state2_epi',
                                                             'patient_11',
                                                             'pui',
                                                             'Fake Jurisdiction',
                                                             'details',
                                                             valid_jurisdiction: false,
                                                             under_hierarchy: true)
  end

  test 'update assigned user' do
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_2', 'all', '9', 'reasoning', valid_assigned_user: true, changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_2', 'all', '', 'reasoning', valid_assigned_user: true, changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '1444', 'reason', valid_assigned_user: true, changed: true)
  end

  test 'update assigned user validation' do
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_2', 'all', '', 'reason', valid_assigned_user: false, changed: false)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '1444', '', valid_assigned_user: false, changed: false)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '0', 'reason', valid_assigned_user: false, changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '1000000', '', valid_assigned_user: false, changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi_enroller', 'patient_4', 'all', '-8', 'reason', valid_assigned_user: false, changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi_enroller', 'patient_2', 'all', '1.5', '', valid_assigned_user: false, changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi_enroller',
                                                     'patient_2',
                                                     'all',
                                                     'not valid',
                                                     'reason',
                                                     valid_assigned_user: false,
                                                     changed: true)
  end

  test 'add report' do
    @@public_health_test_helper.add_report('locals1c1_epi', 'patient_4', 'asymptomatic', SystemTestUtils::ASSESSMENTS['assessment_1'])
  end

  test 'edit report' do
    @@public_health_test_helper.edit_report('locals2c4_epi', 'patient_10', 'pui', 1017, SystemTestUtils::ASSESSMENTS['assessment_2'])
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

  test 'move to household' do
    @@public_health_test_helper.move_to_household('state1_epi', 'patient_2', 'patient_4')
  end
end
