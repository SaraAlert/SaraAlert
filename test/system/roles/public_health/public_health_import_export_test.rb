# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthImportExport'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  ASSESSMENTS = @@system_test_utils.assessments

  ## Dashboard

  test 'verify patient information on dashboard' do
    @@public_health_test_helper.verify_patients_on_dashboard('locals1c2_epi', verify_scope: false)
  end

  test 'verify jurisdiction scope filtering logic on dashboard for state epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('state1_epi_enroller', verify_scope: true)
  end

  test 'verify jurisdiction scope filtering logic on dashboard for local epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('locals1c1_epi', verify_scope: true)
  end

  test 'verify assigned user filtering logic on dashboard for state epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('state2_epi', verify_scope: false)
  end

  test 'verify assigned user filtering logic on dashboard for local epi' do
    @@public_health_test_helper.verify_patients_on_dashboard('locals2c3_epi', verify_scope: false)
    @@public_health_test_helper.verify_patients_on_dashboard('locals2c4_epi', verify_scope: false)
  end

  test 'verify patient details and reports' do
    @@public_health_test_helper.view_patients_details_and_reports('state1_epi')
    @@public_health_test_helper.view_patients_details_and_reports('state2_epi')
  end

  test 'bulk edit case status from exposure to isolation' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_1 patient_2], :exposure, 'all', 'Confirmed',
                                                             'Continue Monitoring in Isolation Workflow', apply_to_group: false)
  end

  test 'bulk edit case status from exposure to closed' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_1 patient_2], :exposure, 'all', 'Confirmed',
                                                             'End Monitoring', apply_to_group: false)
  end

  test 'bulk edit case status from isolation to exposure' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_45 patient_47], :isolation, 'all', 'Unknown',
                                                             nil, apply_to_group: false)
  end

  test 'bulk edit case status from exposure to isolation with household' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_52], :exposure, 'all', 'Confirmed',
                                                             'Continue Monitoring in Isolation Workflow', apply_to_group: true)
  end

  test 'bulk edit case status from isolation to exposure with household' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_54], :isolation, 'all', 'Unknown', nil,
                                                             apply_to_group: true)
  end

  test 'bulk edit close records from exposure workflow' do
    @@public_health_test_helper.bulk_edit_close_records('state1_epi', %w[patient_1 patient_2], :exposure, 'all', '', '',
                                                        apply_to_group: false)
  end

  test 'bulk edit close records from isolation workflow' do
    @@public_health_test_helper.bulk_edit_close_records('state1_epi', %w[patient_45 patient_47], :isolation, 'all', 'Completed Monitoring',
                                                        'reasoning', apply_to_group: false)
  end

  test 'bulk edit close records from exposure workflow with household' do
    @@public_health_test_helper.bulk_edit_close_records('state1_epi', %w[patient_52], :exposure, 'all', 'Duplicate', '', apply_to_group: true)
  end

  test 'bulk edit close records from isolation workflow with household' do
    @@public_health_test_helper.bulk_edit_close_records('state1_epi', %w[patient_54], :isolation, 'all', '', 'details', apply_to_group: true)
  end

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
    @@public_health_test_helper.update_assigned_jurisdiction('state2_epi', 'patient_11', 'pui', 'USA, State 2, County 4', 'details',
                                                             valid_jurisdiction: true, under_hierarchy: true)
    @@public_health_test_helper.update_assigned_jurisdiction('state2_epi', 'patient_10', 'pui', 'USA, State 1', 'details',
                                                             valid_jurisdiction: true, under_hierarchy: false)
  end

  test 'update assigned jurisdiction validation' do
    @@public_health_test_helper.update_assigned_jurisdiction('state2_epi', 'patient_11', 'pui', 'Fake Jurisdiction', 'details',
                                                             valid_jurisdiction: false, under_hierarchy: true)
  end

  test 'update assigned user' do
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_2', 'all', '9', 'reasoning', valid_assigned_user: true,
                                                                                                         changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_2', 'all', '', 'reasoning', valid_assigned_user: true,
                                                                                                        changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '1444', 'reason', valid_assigned_user: true,
                                                                                                         changed: true)
  end

  test 'update assigned user validation' do
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_2', 'all', '', 'reason', valid_assigned_user: false,
                                                                                                     changed: false)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '1444', '', valid_assigned_user: false,
                                                                                                   changed: false)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '0', 'reason', valid_assigned_user: false,
                                                                                                      changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi', 'patient_4', 'all', '10000', '', valid_assigned_user: false,
                                                                                                    changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi_enroller', 'patient_4', 'all', '-8', 'reason', valid_assigned_user: false,
                                                                                                                changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi_enroller', 'patient_2', 'all', '1.5', '', valid_assigned_user: false,
                                                                                                           changed: true)
    @@public_health_test_helper.update_assigned_user('state1_epi_enroller', 'patient_2', 'all', 'not valid', 'reason',
                                                     valid_assigned_user: false, changed: true)
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

  ## Export and import
  test 'export line list csv (exposure)' do
    @@public_health_test_helper.export_line_list_csv('locals2c3_epi', :exposure, :cancel)
    @@public_health_test_helper.export_line_list_csv('state1_epi', :exposure, :export)
  end

  test 'export line list csv (isolation)' do
    @@public_health_test_helper.export_line_list_csv('locals2c4_epi', :isolation, :cancel)
    @@public_health_test_helper.export_line_list_csv('state1_epi_enroller', :isolation, :export)
  end

  test 'export sara alert format (exposure)' do
    @@public_health_test_helper.export_sara_alert_format('locals1c1_epi', :exposure, :cancel)
    @@public_health_test_helper.export_sara_alert_format('state1_epi_enroller', :exposure, :export)
  end

  test 'export sara alert format (isolation)' do
    @@public_health_test_helper.export_sara_alert_format('locals2c3_epi', :isolation, :cancel)
    @@public_health_test_helper.export_sara_alert_format('state1_epi', :isolation, :export)
  end

  test 'export excel purge-eligible monitorees' do
    @@public_health_test_helper.export_excel_purge_eligible_monitorees('state1_epi_enroller', :isolation, :cancel)
    @@public_health_test_helper.export_excel_purge_eligible_monitorees('state1_epi', :exposure, :export)
  end

  test 'export excel all monitorees' do
    @@public_health_test_helper.export_excel_all_monitorees('locals1c1_epi', :exposure, :cancel)
    @@public_health_test_helper.export_excel_all_monitorees('state1_epi', :isolation, :export)
  end

  test 'export excel single monitoree' do
    @@public_health_test_helper.export_excel_single_monitoree('locals2c4_epi', 'patient_10')
  end

  test 'import epi-x to exposure and accept all' do
    @@public_health_test_helper.import_epi_x('state1_epi_enroller', :exposure, 'Epi-X-Format.xlsx', :valid, nil)
  end

  test 'import epi-x to isolation and accept all' do
    @@public_health_test_helper.import_epi_x('state1_epi_enroller', :isolation, 'Epi-X-Format.xlsx', :valid, nil)
  end

  test 'import epi-x to isolation and accept all individually' do
    @@public_health_test_helper.import_epi_x('state2_epi', :isolation, 'Epi-X-Format.xlsx', :valid, [])
  end

  test 'import epi-x to exposure and accept some' do
    @@public_health_test_helper.import_epi_x('locals2c3_epi', :exposure, 'Epi-X-Format.xlsx', :valid, [2, 5, 7, 8])
  end

  test 'import epi-x to isolation and reject all' do
    @@public_health_test_helper.import_epi_x('locals1c1_epi', :isolation, 'Epi-X-Format.xlsx', :valid, (0..10).to_a)
  end

  test 'import epi-x to exposure with duplicate patient and accept duplicates' do
    @@public_health_test_helper.import_epi_x('state5_epi', :exposure, 'Epi-X-Format.xlsx', :valid, nil, accept_duplicates: true)
  end

  test 'import epi-x to isolation with duplicate patient and reject duplicates' do
    @@public_health_test_helper.import_epi_x('state5_epi', :isolation, 'Epi-X-Format.xlsx', :valid, nil, accept_duplicates: false)
  end

  test 'import epi-x to isolation and validate file type' do
    @@public_health_test_helper.import_epi_x('locals2c4_epi', :isolation, 'Invalid-Text-File.txt', :invalid_file, nil)
  end

  test 'import epi-x to exposure and validate file format' do
    @@public_health_test_helper.import_epi_x('locals1c2_epi', :exposure, 'Invalid-Excel-File.xlsx', :invalid_format, nil)
  end

  test 'import epi-x to isolation and validate headers' do
    @@public_health_test_helper.import_epi_x('locals2c4_epi', :isolation, 'Epi-X-Format-Invalid-Headers.xlsx', :invalid_headers, nil)
  end

  test 'import epi-x to exposure and validate empty monitorees list' do
    @@public_health_test_helper.import_epi_x('locals2c3_epi', :exposure, 'Epi-X-Format-Invalid-Monitorees.xlsx', :invalid_monitorees, nil)
  end

  test 'import epi-x to exposure and validate fields' do
    @@public_health_test_helper.import_epi_x('locals1c2_epi', :exposure, 'Epi-X-Format-Invalid-Fields.xlsx', :invalid_fields, nil)
  end

  test 'import epi-x to isolation and validate fields' do
    @@public_health_test_helper.import_epi_x('locals1c2_epi', :isolation, 'Epi-X-Format-Invalid-Fields.xlsx', :invalid_fields, nil)
  end

  test 'import epi-x format and cancel' do
    @@public_health_test_helper.import_and_cancel('locals2c4_epi', :isolation, 'Epi-X-Format.xlsx', 'Epi-X')
  end

  test 'import sara alert format to exposure and accept all' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi', :exposure, 'Sara-Alert-Format.xlsx', :valid, nil)
  end

  test 'import sara alert format to isolation and accept all' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :isolation, 'Sara-Alert-Format.xlsx', :valid, nil)
  end

  test 'import sara alert format to exposure and accept all individually' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :exposure, 'Sara-Alert-Format.xlsx', :valid, [])
  end

  test 'import sara alert format to isolation and accept some' do
    @@public_health_test_helper.import_sara_alert_format('state2_epi', :isolation, 'Sara-Alert-Format.xlsx', :valid, [1, 4, 5, 9])
  end

  test 'import sara alert format to exposure and reject all' do
    @@public_health_test_helper.import_sara_alert_format('locals2c3_epi', :exposure, 'Sara-Alert-Format.xlsx', :valid, (0..10).to_a)
  end

  test 'import sara alert format to isolation with duplicate patient and accept duplicates' do
    @@public_health_test_helper.import_sara_alert_format('state5_epi', :isolation, 'Sara-Alert-Format.xlsx', :valid, nil, accept_duplicates: true)
  end

  test 'import sara alert format to exposure with duplicate patient and reject duplicates' do
    @@public_health_test_helper.import_sara_alert_format('state5_epi', :exposure, 'Sara-Alert-Format.xlsx', :valid, nil, accept_duplicates: false)
  end

  test 'import sara alert format to exposure with custom jurisdictions' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi', :exposure, 'Sara-Alert-Format-With-Jurisdictions.xlsx', :valid, nil)
  end

  test 'import sara alert format to isolation with custom jurisdictions' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :isolation, 'Sara-Alert-Format-With-Jurisdictions.xlsx', :valid, nil)
  end

  test 'import sara alert format to exposure and validate file type' do
    @@public_health_test_helper.import_sara_alert_format('locals1c2_epi', :exposure, 'Invalid-Text-File.txt', :invalid_file, nil)
  end

  test 'import sara alert format to isolation and validate file format' do
    @@public_health_test_helper.import_sara_alert_format('locals2c4_epi', :isolation, 'Invalid-Excel-File.xlsx', :invalid_format, nil)
  end

  test 'import sara alert format to exposure and validate headers' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi', :exposure, 'Sara-Alert-Format-Invalid-Headers.xlsx', :invalid_headers, nil)
  end

  test 'import sara alert format to isolation and validate empty monitorees list' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :isolation, 'Sara-Alert-Format-Invalid-Monitorees.xlsx',
                                                         :invalid_monitorees, nil)
  end

  test 'import sara alert format to exposure and validate fields' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi', :exposure, 'Sara-Alert-Format-Invalid-Fields.xlsx', :invalid_fields, nil)
  end

  test 'import sara alert format to isolation and validate fields' do
    @@public_health_test_helper.import_sara_alert_format('state2_epi', :isolation, 'Sara-Alert-Format-Invalid-Fields.xlsx', :invalid_fields, nil)
  end

  test 'import sara alert format to exposure and validate jurisdiction path' do
    @@public_health_test_helper.import_sara_alert_format('locals2c4_epi', :exposure, 'Sara-Alert-Format-With-Jurisdictions.xlsx', :invalid_fields, [])
  end

  test 'import sara alert format and cancel' do
    @@public_health_test_helper.import_and_cancel('locals2c4_epi', :exposure, 'Sara-Alert-Format.xlsx', 'Sara Alert Format')
  end

  # TODO: Re-enable when migrating away from GitHub LFS
  # test 'download sara alert format guidance from exposure workflow' do
  #   @@public_health_test_helper.download_sara_alert_format_guidance('state1_epi', :exposure)
  # end

  # TODO: Re-enable when migrating away from GitHub LFS
  # test 'download sara alert format guidance from isolation workflow' do
  #   @@public_health_test_helper.download_sara_alert_format_guidance('locals2c3_epi', :isolation)
  # end
end
