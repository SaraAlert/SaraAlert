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

  def verify_patients_on_dashboard(user_name)
    jurisdiction_id = @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard_verifier.verify_patients_on_dashboard(jurisdiction_id)
    @@system_test_utils.logout
  end

  def view_patients_details_and_reports(user_name)
    jurisdiction_id = @@system_test_utils.login(user_name)
    @@public_health_monitoring_monitoree_page.view_patients_details_and_reports(jurisdiction_id)
    @@system_test_utils.logout
  end

  def update_monitoring_status(user_name, patient_key, old_tab, new_tab, monitoring_status, status_change_reason, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(old_tab, patient_key)
    @@public_health_monitoring_actions.update_monitoring_status(user_name, monitoring_status, status_change_reason, reasoning)
    @@system_test_utils.return_to_dashboard(nil)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(new_tab, patient_key)
    @@system_test_utils.logout
  end

  def update_exposure_risk_assessment(user_name, patient_key, tab, exposure_risk_assessment, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_actions.update_exposure_risk_assessment(user_name, exposure_risk_assessment, reasoning)
    @@system_test_utils.logout
  end

  def update_monitoring_plan(user_name, patient_key, tab, monitoring_plan, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_actions.update_monitoring_plan(user_name, monitoring_plan, reasoning)
    @@system_test_utils.logout
  end

  def update_latest_public_health_action(user_name, patient_key, tab, latest_public_health_action, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_actions.update_latest_public_health_action(user_name, latest_public_health_action, reasoning)
    @@system_test_utils.logout
  end

  def add_additional_public_health_action(user_name, patient_key, tab, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_actions.add_additional_public_health_action(user_name, reasoning, false)
    @@public_health_monitoring_actions.add_additional_public_health_action(user_name, reasoning)
    @@system_test_utils.logout
  end

  def update_current_workflow(user_name, patient_key, tab, current_workflow, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_actions.update_current_workflow(user_name, current_workflow, reasoning)
    @@system_test_utils.logout
  end

  def update_assigned_jurisdiction(user_name, patient_key, tab, jurisdiction, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_actions.update_assigned_jurisdiction(user_name, jurisdiction, reasoning)
    @@system_test_utils.logout
  end

  def add_report(user_name, patient_key, tab, assessment)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_reports.add_report(user_name, assessment)
    @@system_test_utils.logout
  end

  def edit_report(user_name, patient_key, old_tab, assessment_id, assessment, new_tab)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(old_tab, patient_key)
    @@public_health_monitoring_reports.edit_report(user_name, patient_key, assessment_id, assessment, true)
    @@system_test_utils.logout
  end

  def add_note_to_report(user_name, patient_key, tab, assessment_id, note)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_reports.add_note_to_report(user_name, patient_key, assessment_id, note, false)
    @@public_health_monitoring_reports.add_note_to_report(user_name, patient_key, assessment_id, note, true)
  end

  def mark_all_as_reviewed(user_name, patient_key, tab, reasoning)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_reports.mark_all_as_reviewed(user_name, reasoning)
    @@system_test_utils.logout
  end

  def pause_notifications(user_name, patient_key, tab)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_reports.pause_notifications(user_name, true)
    @@public_health_monitoring_reports.pause_notifications(user_name, false)
    @@system_test_utils.logout
  end

  def add_comment(user_name, patient_key, tab, comment)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient_key)
    @@public_health_monitoring_history.add_comment(user_name, comment)
    @@system_test_utils.logout
  end

  def export_linelist_data_to_csv(user_name)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.export_linelist_data_to_csv
    @@system_test_utils.logout
  end

  def export_comprehensive_data_to_csv(user_name)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.export_comprehensive_data_to_csv
    @@system_test_utils.logout
  end

  def import_epi_x_data(user_name)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.import_epi_x_data
  end

  def import_sara_alert_format_data(user_name)
    @@system_test_utils.login(user_name)
    @@public_health_monitoring_dashboard.import_sara_alert_format_data
  end
end