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
    @@public_health_monitoring_helper.update_latest_public_health_action('state1_epi_enroller', 'patient_7', 'pui', 'Recommended medical evaluation of symptoms', 'details')
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

  test 'export line list csv from exposure workflow' do
    @@public_health_monitoring_helper.export_line_list_csv('locals2c3_epi', :exposure)
  end

  test 'export line list csv from isolation workflow' do
    @@public_health_monitoring_helper.export_line_list_csv('locals2c4_epi', :isolation)
  end

  test 'export sara alert format csv from exposure workflow' do
    @@public_health_monitoring_helper.export_sara_alert_format('locals2c4_epi', :exposure)
  end

  test 'export sara alert format csv from isolation workflow' do
    @@public_health_monitoring_helper.export_sara_alert_format('locals2c3_epi', :isolation)
  end

  test 'export excel purge-eligible monitorees' do
    @@public_health_monitoring_helper.export_excel_purge_eligible_monitorees('state1_epi', :download)
  end

  test 'export excel purge-eligible monitorees and cancel' do
    @@public_health_monitoring_helper.export_excel_purge_eligible_monitorees('locals1c1_epi', :cancel)
  end

  test 'export excel all monitorees' do
    @@public_health_monitoring_helper.export_excel_all_monitorees('state1_epi', :download)
  end

  test 'export excel all monitorees and cancel' do
    @@public_health_monitoring_helper.export_excel_all_monitorees('locals1c2_epi', :cancel)
  end

  test 'export excel single monitoree' do
    @@public_health_monitoring_helper.export_excel_single_monitoree('locals2c4_epi', 'patient_10')
  end
  
  test 'import epi-x to exposure and accept all' do
    @@public_health_monitoring_helper.import_epi_x('state1_epi_enroller', :exposure, 'Epi-X-Format.xlsx', :valid, nil)
  end

  test 'import epi-x to isolation and accept all individually' do
    @@public_health_monitoring_helper.import_epi_x('state2_epi', :isolation, 'Epi-X-Format.xlsx', :valid, [])
  end

  test 'import epi-x to exposure and accept some' do
    @@public_health_monitoring_helper.import_epi_x('locals2c3_epi', :exposure, 'Epi-X-Format.xlsx', :valid, [2, 5, 7, 8])
  end

  test 'import epi-x to isolation and reject all' do
    @@public_health_monitoring_helper.import_epi_x('locals1c1_epi', :isolation, 'Epi-X-Format.xlsx', :valid, (0..10).to_a)
  end

  test 'import epi-x to exposure with duplicate patient and accept duplicates' do
    @@public_health_monitoring_helper.import_epi_x('jurisdiction_10_epi', :exposure, 'Epi-X-Format.xlsx', :valid, nil, true)
  end

  test 'import epi-x to isolation with duplicate patient and reject duplicates' do
    @@public_health_monitoring_helper.import_epi_x('jurisdiction_10_epi', :isolation, 'Epi-X-Format.xlsx', :valid, nil, false)
  end

  test 'import epi-x to exposure and validate file type' do
    @@public_health_monitoring_helper.import_epi_x('locals2c4_epi', :exposure, 'Invalid-Text-File.txt', :invalid_file, nil)
  end

  test 'import epi-x to isolation and validate file format' do
    @@public_health_monitoring_helper.import_epi_x('locals1c2_epi', :isolation, 'Invalid-Excel-File.xlsx', :invalid_format, nil)
  end

  test 'import epi-x to exposure and validate fields' do
    @@public_health_monitoring_helper.import_epi_x('locals1c2_epi', :isolation, 'Epi-X-Format-Invalid.xlsx', :invalid_fields, nil)
  end

  test 'import sara alert format to isolation and accept all' do
    @@public_health_monitoring_helper.import_sara_alert_format('state1_epi', :isolation, 'Sara-Alert-Format.xlsx', :valid, nil)
  end

  test 'import sara alert format to exposure and accept all individually' do
    @@public_health_monitoring_helper.import_sara_alert_format('locals2c4_epi', :exposure, 'Sara-Alert-Format.xlsx', :valid, [])
  end

  test 'import sara alert format to isolation and accept some' do
    @@public_health_monitoring_helper.import_sara_alert_format('state2_epi', :isolation, 'Sara-Alert-Format.xlsx', :valid, [1, 4, 5, 9])
  end

  test 'import sara alert format to exposure and reject all' do
    @@public_health_monitoring_helper.import_sara_alert_format('locals2c3_epi', :exposure, 'Sara-Alert-Format.xlsx', :valid, (0..10).to_a)
  end

  test 'import sara alert format to isolation with duplicate patient and accept duplicates' do
    @@public_health_monitoring_helper.import_sara_alert_format('jurisdiction_10_epi', :isolation, 'Sara-Alert-Format.xlsx', :valid, nil, true)
  end

  test 'import sara alert format to exposure with duplicate patient and reject duplicates' do
    @@public_health_monitoring_helper.import_sara_alert_format('jurisdiction_10_epi', :exposure, 'Sara-Alert-Format.xlsx', :valid, nil, false)
  end

  test 'import sara alert format to exposure and validate file type' do
    @@public_health_monitoring_helper.import_sara_alert_format('locals1c2_epi', :exposure, 'Invalid-Text-File.txt', :invalid_file, nil)
  end

  test 'import sara alert format to isolation and validate file format' do
    @@public_health_monitoring_helper.import_sara_alert_format('locals2c4_epi', :isolation, 'Invalid-Excel-File.xlsx', :invalid_format, nil)
  end

  test 'import sara alert format to exposure and validate fields' do
    @@public_health_monitoring_helper.import_sara_alert_format('state2_epi', :exposure, 'Sara-Alert-Format-Invalid.xlsx', :invalid_fields, nil)
  end

  test 'download sara alert format guidance from exposure workflow' do
    # TODO: Re-enable when migrating away from GitHub LFS
    #@@public_health_monitoring_helper.download_sara_alert_format_guidance('state1_epi', :exposure)
  end

  test 'download sara alert format guidance from isolation workflow' do
    # TODO: Re-enable when migrating away from GitHub LFS
    #@@public_health_monitoring_helper.download_sara_alert_format_guidance('locals2c3_epi', :isolation)
  end
end
