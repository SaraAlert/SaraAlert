# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard/dashboard'
require_relative 'dashboard/dashboard_verifier'
require_relative 'patient_page/actions'
require_relative 'patient_page/history'
require_relative 'patient_page/reports'
require_relative 'patient_page/patient_page'
require_relative '../../lib/system_test_utils'

class PublicHealthTestHelper < ApplicationSystemTestCase
  @@public_health_dashboard = PublicHealthDashboard.new(nil)
  @@public_health_dashboard_verifier = PublicHealthDashboardVerifier.new(nil)
  @@public_health_patient_page_actions = PublicHealthPatientPageActions.new(nil)
  @@public_health_patient_page_history = PublicHealthPatientPageHistory.new(nil)
  @@public_health_patient_page_reports = PublicHealthPatientPageReports.new(nil)
  @@public_health_patient_page = PublicHealthPatientPage.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  # rubocop:disable Metrics/ParameterLists
  def verify_patients_on_dashboard(user_label, verify_scope: false)
    jurisdiction_id = @@system_test_utils.login(user_label)
    @@public_health_dashboard_verifier.verify_patients_on_dashboard(jurisdiction_id, verify_scope: verify_scope)
    @@system_test_utils.logout
  end

  def view_patients_details_and_reports(user_label)
    jurisdiction_id = @@system_test_utils.login(user_label)
    @@public_health_patient_page.view_patients_details_and_reports(jurisdiction_id)
    @@system_test_utils.logout
  end

  def bulk_edit_update_case_status(user_label, patient_labels, workflow, tab, case_status, next_step, apply_to_group: false)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.select_monitorees_for_bulk_edit(workflow, tab, patient_labels)
    @@public_health_dashboard.bulk_edit_update_case_status(workflow, case_status, next_step, apply_to_group: apply_to_group)
    assertions = {
      case_status: case_status,
      isolation: %w[Confirmed Probable].include?(case_status) && next_step == 'Continue Monitoring in Isolation Workflow',
      monitoring: next_step != 'End Monitoring'
    }
    patient_labels.each do |label|
      @@public_health_dashboard_verifier.search_for_and_verify_patient_monitoring_actions(label, assertions,
                                                                                          apply_to_group: apply_to_group)
    end
    @@system_test_utils.logout
  end

  def bulk_edit_close_records(user_label, patient_labels, workflow, tab, monitoring_reason, reasoning, apply_to_group: false)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.select_monitorees_for_bulk_edit(workflow, tab, patient_labels)
    @@public_health_dashboard.bulk_edit_close_records(monitoring_reason, reasoning, apply_to_group: apply_to_group)
    assertions = { monitoring: false, monitoring_reason: monitoring_reason }
    patient_labels.each do |label|
      @@public_health_dashboard_verifier.search_for_and_verify_patient_monitoring_actions(label, assertions,
                                                                                          apply_to_group: apply_to_group)
    end
    @@system_test_utils.logout
  end

  def update_monitoring_status(user_label, patient_label, old_tab, new_tab, monitoring_status, monitoring_reason, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(old_tab, patient_label)
    @@public_health_patient_page_actions.update_monitoring_status(user_label, patient_label, monitoring_status, monitoring_reason, reasoning)
    @@system_test_utils.return_to_dashboard(nil)
    @@public_health_dashboard.search_for_and_view_patient(new_tab, patient_label)
    @@system_test_utils.logout
  end

  def update_exposure_risk_assessment(user_label, patient_label, tab, exposure_risk_assessment, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_actions.update_exposure_risk_assessment(user_label, patient_label, exposure_risk_assessment, reasoning)
    @@system_test_utils.logout
  end

  def update_monitoring_plan(user_label, patient_label, tab, monitoring_plan, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_actions.update_monitoring_plan(user_label, patient_label, monitoring_plan, reasoning)
    @@system_test_utils.logout
  end

  def update_latest_public_health_action(user_label, patient_label, tab, latest_public_health_action, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_actions.update_latest_public_health_action(user_label, patient_label, latest_public_health_action, reasoning)
    @@system_test_utils.logout
  end

  def update_assigned_jurisdiction(user_label, patient_label, tab, jurisdiction, reasoning, valid_jurisdiction: true, under_hierarchy: true)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_actions.update_assigned_jurisdiction(user_label, patient_label, jurisdiction, reasoning,
                                                                      valid_jurisdiction: valid_jurisdiction, under_hierarchy: under_hierarchy)
    @@system_test_utils.logout
  end

  def update_assigned_user(user_label, patient_label, tab, assigned_user, reasoning, valid_assigned_user: true, changed: true)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_actions.update_assigned_user(user_label, patient_label, assigned_user, reasoning,
                                                              valid_assigned_user: valid_assigned_user, changed: changed)
    @@system_test_utils.logout
  end

  def add_report(user_label, patient_label, tab, assessment)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_reports.add_report(user_label, assessment)
    @@system_test_utils.logout
  end

  def edit_report(user_label, patient_label, old_tab, assessment_id, assessment)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(old_tab, patient_label)
    @@public_health_patient_page_reports.edit_report(user_label, assessment_id, assessment, submit: true)
    @@system_test_utils.logout
  end

  def add_note_to_report(user_label, patient_label, tab, assessment_id, note)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_reports.add_note_to_report(user_label, assessment_id, note, submit: false)
    @@public_health_patient_page_reports.add_note_to_report(user_label, assessment_id, note, submit: true)
  end

  def mark_all_as_reviewed(user_label, patient_label, tab, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_reports.mark_all_as_reviewed(user_label, reasoning)
    @@system_test_utils.logout
  end

  def pause_notifications(user_label, patient_label, tab)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_reports.pause_notifications(user_label, submit: true)
    @@public_health_patient_page_reports.pause_notifications(user_label, submit: false)
    @@system_test_utils.logout
  end

  def add_comment(user_label, patient_label, tab, comment)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_patient_page_history.add_comment(user_label, comment)
    @@system_test_utils.logout
  end

  def export_line_list_csv(user_label, workflow, action)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.export_line_list_csv(user_label, workflow, action)
    @@system_test_utils.logout
  end

  def export_sara_alert_format(user_label, workflow, action)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.export_sara_alert_format(user_label, workflow, action)
    @@system_test_utils.logout
  end

  def export_excel_purge_eligible_monitorees(user_label, workflow, action)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.export_excel_purge_eligible_monitorees(user_label, workflow, action)
    @@system_test_utils.logout
  end

  def export_excel_all_monitorees(user_label, workflow, action)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.export_excel_all_monitorees(user_label, workflow, action)
    @@system_test_utils.logout
  end

  def export_excel_single_monitoree(user_label, patient_label)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.export_excel_single_monitoree(patient_label)
    @@system_test_utils.logout
  end

  def import_epi_x(user_label, workflow, file_name, validity, rejects, accept_duplicates: false)
    jurisdiction_id = @@system_test_utils.login(user_label)
    @@public_health_dashboard.import_epi_x(jurisdiction_id, workflow, file_name, validity, rejects, accept_duplicates)
    @@system_test_utils.logout
  end

  def import_sara_alert_format(user_label, workflow, file_name, validity, rejects, accept_duplicates: false)
    jurisdiction_id = @@system_test_utils.login(user_label)
    @@public_health_dashboard.import_sara_alert_format(jurisdiction_id, workflow, file_name, validity, rejects, accept_duplicates)
    @@system_test_utils.logout
  end

  def import_and_cancel(user_label, workflow, file_name, file_type)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.import_and_cancel(workflow, file_name, file_type)
    @@system_test_utils.logout
  end

  def download_sara_alert_format_guidance(user_label, workflow)
    @@system_test_utils.login(user_label)
    @@public_health_dashboard.download_sara_alert_format_guidance(workflow)
    @@system_test_utils.logout
  end
  # rubocop:enable Metrics/ParameterLists
end
