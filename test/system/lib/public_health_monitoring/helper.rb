# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'actions'
require_relative 'dashboard'
require_relative 'history'
require_relative 'reports'
require_relative 'monitoree_page'
require_relative 'dashboard_verifier'
require_relative '../system_test_utils'

class PublicHealthMonitoringHelper < ApplicationSystemTestCase
  @@public_health_monitoring_actions = PublicHealthMonitoringActions.new(nil)
  @@public_health_monitoring_dashboard = PublicHealthMonitoringDashboard.new(nil)
  @@public_health_monitoring_history = PublicHealthMonitoringHistory.new(nil)
  @@public_health_monitoring_reports = PublicHealthMonitoringReports.new(nil)
  @@public_health_monitoring_monitoree_page = PublicHealthMonitoringMonitoreePage.new(nil)
  @@public_health_monitoring_dashboard_verifier = PublicHealthMonitoringDashboardVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_patients_on_dashboard(user_label, verify_scope=false)
    jurisdiction_id = @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard_verifier.verify_patients_on_dashboard(jurisdiction_id, verify_scope)
    @@system_test_utils.logout
  end

  def view_patients_details_and_reports(user_label)
    jurisdiction_id = @@system_test_utils.login(user_label)
    @@public_health_monitoring_monitoree_page.view_patients_details_and_reports(jurisdiction_id)
    @@system_test_utils.logout
  end

  def update_monitoring_status(user_label, patient_label, old_tab, new_tab, monitoring_status, status_change_reason, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(old_tab, patient_label)
    @@public_health_monitoring_actions.update_monitoring_status(user_label, monitoring_status, status_change_reason, reasoning)
    @@system_test_utils.return_to_dashboard(nil)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(new_tab, patient_label)
    @@system_test_utils.logout
  end

  def update_exposure_risk_assessment(user_label, patient_label, tab, exposure_risk_assessment, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_actions.update_exposure_risk_assessment(user_label, exposure_risk_assessment, reasoning)
    @@system_test_utils.logout
  end

  def update_monitoring_plan(user_label, patient_label, tab, monitoring_plan, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_actions.update_monitoring_plan(user_label, monitoring_plan, reasoning)
    @@system_test_utils.logout
  end

  def update_latest_public_health_action(user_label, patient_label, tab, latest_public_health_action, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_actions.update_latest_public_health_action(user_label, latest_public_health_action, reasoning)
    @@system_test_utils.logout
  end

  def update_assigned_jurisdiction(user_label, patient_label, tab, jurisdiction, reasoning, valid_jurisdiction=true, under_hierarchy=true)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_actions.update_assigned_jurisdiction(user_label, jurisdiction, reasoning, valid_jurisdiction, under_hierarchy)
    @@system_test_utils.logout
  end

  def update_assigned_user(user_label, patient_label, tab, assigned_user, reasoning, valid_assigned_user=true, changed=true)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_actions.update_assigned_user(user_label, assigned_user, reasoning, valid_assigned_user, changed)
    @@system_test_utils.logout
  end

  def add_report(user_label, patient_label, tab, assessment)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_reports.add_report(user_label, assessment)
    @@system_test_utils.logout
  end

  def edit_report(user_label, patient_label, old_tab, assessment_id, assessment, new_tab)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(old_tab, patient_label)
    @@public_health_monitoring_reports.edit_report(user_label, patient_label, assessment_id, assessment, true)
    @@system_test_utils.logout
  end

  def add_note_to_report(user_label, patient_label, tab, assessment_id, note)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_reports.add_note_to_report(user_label, patient_label, assessment_id, note, false)
    @@public_health_monitoring_reports.add_note_to_report(user_label, patient_label, assessment_id, note, true)
  end

  def mark_all_as_reviewed(user_label, patient_label, tab, reasoning)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_reports.mark_all_as_reviewed(user_label, reasoning)
    @@system_test_utils.logout
  end

  def pause_notifications(user_label, patient_label, tab)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_reports.pause_notifications(user_label, true)
    @@public_health_monitoring_reports.pause_notifications(user_label, false)
    @@system_test_utils.logout
  end

  def add_comment(user_label, patient_label, tab, comment)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_label)
    @@public_health_monitoring_history.add_comment(user_label, comment)
    @@system_test_utils.logout
  end

  def export_line_list_csv(user_label, workflow, action)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.export_line_list_csv(user_label, workflow, action)
    @@system_test_utils.logout
  end

  def export_sara_alert_format(user_label, workflow, action)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.export_sara_alert_format(user_label, workflow, action)
    @@system_test_utils.logout
  end

  def export_excel_purge_eligible_monitorees(user_label, workflow, action)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.export_excel_purge_eligible_monitorees(user_label, workflow, action)
    @@system_test_utils.logout
  end

  def export_excel_all_monitorees(user_label, workflow, action)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.export_excel_all_monitorees(user_label, workflow, action)
    @@system_test_utils.logout
  end

  def export_excel_single_monitoree(user_label, patient_label)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.export_excel_single_monitoree(patient_label)
    @@system_test_utils.logout
  end

  def import_epi_x(user_label, workflow, file_name, validity, rejects, accept_duplicates=false)
    jurisdiction_id = @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.import_epi_x(jurisdiction_id, workflow, file_name, validity, rejects, accept_duplicates)
    @@system_test_utils.logout
  end

  def import_sara_alert_format(user_label, workflow, file_name, validity, rejects, accept_duplicates=false)
    jurisdiction_id = @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.import_sara_alert_format(jurisdiction_id, workflow, file_name, validity, rejects, accept_duplicates)
    @@system_test_utils.logout
  end

  def download_sara_alert_format_guidance(user_label, workflow)
    @@system_test_utils.login(user_label)
    @@public_health_monitoring_dashboard.download_sara_alert_format_guidance(workflow)
    @@system_test_utils.logout
  end
end