# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'lib/public_health_monitoring/helper'
require_relative 'lib/system_test_utils'

class PublicHealthTest < ApplicationSystemTestCase
  @@public_health_monitoring_helper = PublicHealthMonitoringHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  ASSESSMENTS = @@system_test_utils.get_assessments

  test 'view patient information on dashboard' do
    @@public_health_monitoring_helper.verify_patients_on_dashboard('state1_epi')
    @@public_health_monitoring_helper.verify_patients_on_dashboard('locals1c1_epi')
    @@public_health_monitoring_helper.verify_patients_on_dashboard('locals1c2_epi')
    @@public_health_monitoring_helper.verify_patients_on_dashboard('state2_epi')
    @@public_health_monitoring_helper.verify_patients_on_dashboard('locals2c3_epi')
    @@public_health_monitoring_helper.verify_patients_on_dashboard('locals2c4_epi')
    @@public_health_monitoring_helper.verify_patients_on_dashboard('state1_epi_enroller')
  end

  test 'verify patient details and reports' do
    @@public_health_monitoring_helper.view_patients_details_and_reports('state1_epi')
    @@public_health_monitoring_helper.view_patients_details_and_reports('state2_epi')
  end

  test 'update monitoring status' do
    @@public_health_monitoring_helper.update_monitoring_status('state1_epi', 'patient_2', 'non-reporting', 'closed', 'Not Monitoring', 'Completed Monitoring', 'details')
  end

  test 'update exposure risk assessment' do
    @@public_health_monitoring_helper.update_exposure_risk_assessment('locals1c1_epi', 'patient_4', 'asymptomatic', 'High', 'details')
  end

  test 'update monitoring plan' do
    @@public_health_monitoring_helper.update_monitoring_plan('locals1c2_epi', 'patient_6', 'pui', 'Daily active monitoring', 'details')
  end

  test 'update latest public health action' do
    @@public_health_monitoring_helper.update_latest_public_health_action('state1_epi_enroller', 'patient_7', 'pui', 'Laboratory report results – positive', 'details')
  end

  test 'add additional public health action' do
    @@public_health_monitoring_helper.add_additional_public_health_action('state1_epi', 'patient_2', 'non-reporting', 'details')
    @@public_health_monitoring_helper.add_additional_public_health_action('state2_epi', 'patient_10', 'pui', 'details')
  end

  test 'update current workflow' do
    @@public_health_monitoring_helper.update_current_workflow('state1_epi', 'patient_3', 'symptomatic', 'Isolation', 'details')
  end

  test 'update assigned jurisdiction' do
    @@public_health_monitoring_helper.update_assigned_jurisdiction('state2_epi', 'patient_11', 'pui', 'Fake Jurisdiction', 'details', false, true)
    @@public_health_monitoring_helper.update_assigned_jurisdiction('state2_epi', 'patient_11', 'pui', 'USA, State 2, County 4', 'details', true, true)
    @@public_health_monitoring_helper.update_assigned_jurisdiction('state2_epi', 'patient_10', 'pui', 'USA, State 1', 'details', true, false)
  end

  test 'add report' do
    @@public_health_monitoring_helper.add_report('locals1c1_epi', 'patient_4', 'asymptomatic', ASSESSMENTS["assessment_1"])
  end

  test 'edit report' do
    @@public_health_monitoring_helper.edit_report('locals2c4_epi', 'patient_10', 'pui', 1017, ASSESSMENTS["assessment_2"], 'Symptomatic')
  end

  test 'add note to report' do
    @@public_health_monitoring_helper.add_note_to_report('state2_epi', 'patient_10', 'pui', 1016, 'note')
  end

  test 'mark all reports as reviewed' do
    @@public_health_monitoring_helper.mark_all_as_reviewed('state1_epi_enroller', 'patient_5', 'closed', 'comment')
  end

  test 'pause notifications' do
    @@public_health_monitoring_helper.pause_notifications('state1_epi', 'patient_2', 'non-reporting')
    @@public_health_monitoring_helper.pause_notifications('state1_epi', 'patient_2', 'non-reporting')
  end

  test 'add comment' do
    @@public_health_monitoring_helper.add_comment('locals2c3_epi', 'patient_11', 'pui', 'comment')
  end

  test 'export linelist data to csv' do
    @@public_health_monitoring_helper.export_linelist_data_to_csv('locals2c4_epi')
  end

  test 'export comprehensive data to csv' do
    @@public_health_monitoring_helper.export_comprehensive_data_to_csv('locals2c4_epi')
  end

  test 'import epi-x data' do
    @@public_health_monitoring_helper.import_epi_x_data('locals1c1_epi')
  end

  test 'import sara alert format data' do
    @@public_health_monitoring_helper.import_sara_alert_format_data('locals1c2_epi')
  end
end
