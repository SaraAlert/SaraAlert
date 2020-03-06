require "application_system_test_case"

require_relative "components/public_health_monitoring/actions"
require_relative "components/public_health_monitoring/dashboard"
require_relative "components/public_health_monitoring/history"
require_relative "components/public_health_monitoring/reports"
require_relative "lib/system_test_utils"

class PublicHealthTest < ApplicationSystemTestCase
  
  @@public_health_monitoring_actions = PublicHealthMonitoringActions.new(nil)
  @@public_health_monitoring_dashboard = PublicHealthMonitoringDashboard.new(nil)
  @@public_health_monitoring_history = PublicHealthMonitoringHistory.new(nil)
  @@public_health_monitoring_reports = PublicHealthMonitoringReports.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  PATIENTS = @@system_test_utils.get_patients
  REPORTS = @@system_test_utils.get_reports
  USERS = @@system_test_utils.get_users

  test "epis can only view and search for patients under their jurisdiction" do
    search_for_and_verify_patients_under_jurisdiction(USERS["state1_epi"], [3], [2, 6, 7], [4, 8], [5])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals1c1_epi"], [], [], [4], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals1c2_epi"], [], [6], [], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["state2_epi"], [], [11], [9, 10], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals2c3_epi"], [], [11], [], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals2c4_epi"], [], [], [10], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["state1_epi_enroller"], [3], [2, 6, 7], [4, 8], [5])
  end
  
  test "update monitoring status" do
    update_monitoring_status(USERS["state1_epi"], PATIENTS["patient_2"], "Non-Reporting", "Closed", "Not Monitoring", "Completed Monitoring", "details")
  end

  test "update exposure risk assessment" do
    update_exposure_risk_assessment(USERS["locals1c1_epi"], PATIENTS["patient_4"], "Asymptomatic", "High", "details")    
  end

  test "update monitoring plan" do
    update_monitoring_plan(USERS["locals1c2_epi"], PATIENTS["patient_6"], "Non-Reporting", "Daily active monitoring", "details")  
  end

  test "update assigned jurisdiction" do
    update_jurisdiction(USERS["state2_epi"], PATIENTS["patient_11"], "Non-Reporting", "USA, State 2, County 4", "details")
    search_for_and_verify_patients_under_jurisdiction(USERS["state2_epi"], [], [11], [9, 10], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals2c3_epi"], [], [], [], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals2c4_epi"], [], [11], [10], [])
  end

  test "view reports" do
    view_reports(USERS["state1_epi"], PATIENTS["patient_2"], "Non-Reporting", nil)
  end

  test "add report" do
    add_report(USERS["locals1c1_epi"], PATIENTS["patient_4"], "Asymptomatic", 98, false, false)
  end

  test "edit report" do
    edit_report(USERS["state2_epi"], PATIENTS["patient_10"], "Asymptomatic", REPORTS["patient_10_assessment_3"], 102, true, false)
  end

  test "clear all reports" do
    clear_all_reports(USERS["state1_epi_enroller"], PATIENTS["patient_5"], "Closed", "details")
  end

  test "add comment" do
    add_comment(USERS["locals2c3_epi"], PATIENTS["patient_11"], "Non-Reporting", "comment")
  end

  test "export data to excel" do
    export_data_to_excel(USERS["state1_epi"])
  end

  test "export data to csv" do
    export_data_to_csv(USERS["locals2c4_epi"])
  end

  def search_for_and_verify_patients_under_jurisdiction(epi, symptomatic_patients, non_reporting_patients, asymptomatic_patients, closed_patients)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.verify_patients_under_tab("Symptomatic", PATIENTS, symptomatic_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab("Non-Reporting", PATIENTS, non_reporting_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab("Asymptomatic", PATIENTS, asymptomatic_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab("Closed", PATIENTS, closed_patients)
    @@system_test_utils.logout
  end

  def update_monitoring_status(epi, patient, old_tab, new_tab, monitoring_status, status_change_reason, reasoning)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(old_tab, patient)
    @@public_health_monitoring_actions.update_monitoring_status(monitoring_status, status_change_reason, reasoning)
    ## verify update in monitoring actions and history
    @@public_health_monitoring_dashboard.return_to_dashboard
    @@public_health_monitoring_dashboard.verify_patient_under_tab(new_tab, patient)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(new_tab, patient)
    ## verify update in monitoring actions and history after refresh
    @@system_test_utils.logout
  end

  def update_exposure_risk_assessment(epi, patient, tab, exposure_risk_assessment, reasoning)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    @@public_health_monitoring_actions.update_exposure_risk_assessment(exposure_risk_assessment, reasoning)
    ## verify update in exposure risk assessment in actions and history
    @@public_health_monitoring_dashboard.return_to_dashboard
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    ## verify update in exposure risk assessment in actions and history after refresh
    @@system_test_utils.logout
  end

  def update_monitoring_plan(epi, patient, tab, monitoring_plan, reasoning)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    @@public_health_monitoring_actions.update_monitoring_plan(monitoring_plan, reasoning)
    ## verify update in monitoring plan in actions and history
    @@public_health_monitoring_dashboard.return_to_dashboard
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    ## verify update in monitoring plan in actions and history after refresh
    @@system_test_utils.logout
  end

  def update_jurisdiction(epi, patient, tab, jurisdiction, reasoning)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    @@public_health_monitoring_actions.update_jurisdiction(jurisdiction, reasoning)
    ## verify update in jurisdiction plan in actions and history
    @@system_test_utils.logout
  end

  def add_comment(epi, patient, tab, comment)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    @@public_health_monitoring_history.add_comment(comment)
    ## verify comment in history
    @@public_health_monitoring_dashboard.return_to_dashboard
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    ## verify comment in history after refresh
    @@system_test_utils.logout
  end

  def view_reports(epi, patient, tab, expected_reports)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    ## verify reports are there
    @@system_test_utils.logout
  end

  def add_report(epi, patient, tab, temperature, cough, difficulty_breathing)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    @@public_health_monitoring_reports.add_report(temperature, cough, difficulty_breathing)
    ## verify report is there
    @@system_test_utils.logout
  end

  def edit_report(epi, patient, tab, report, temperature, cough, difficulty_breathing)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    @@public_health_monitoring_reports.edit_report(report, temperature, cough, difficulty_breathing)
    ## verify report is updated
    @@system_test_utils.logout
  end

  def clear_all_reports(epi, patient, tab, reasoning)
    @@system_test_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(tab, patient)
    @@public_health_monitoring_reports.clear_all_reports(reasoning)
    ## verify reports are cleared
    @@system_test_utils.logout
  end

  def export_data_to_excel(epi)
    @@system_test_utils.login(epi)
    assert_selector "span", text: "Excel"
    # click_on "Excel"
    ## verify that file is downloaded
    @@system_test_utils.logout
  end

  def export_data_to_csv(epi)
    @@system_test_utils.login(epi)
    assert_selector "span", text: "CSV"
    # click_on "CSV"
    ## verify that file is downloaded
    @@system_test_utils.logout
  end

end
