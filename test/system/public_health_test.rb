require "application_system_test_case"

require_relative "components/public_health_monitoring/actions"
require_relative "components/public_health_monitoring/dashboard"
require_relative "components/public_health_monitoring/history"
require_relative "components/public_health_monitoring/reports"
require_relative "lib/public_health_monitoring/utils"

class PublicHealthTest < ApplicationSystemTestCase
  
  ASSESSMENTS = YAML.load(File.read(__dir__ + "/../fixtures/assessments.yml"))
  PATIENTS = YAML.load(File.read(__dir__ + "/../fixtures/patients.yml"))
  USERS = YAML.load(File.read(__dir__ + "/../fixtures/users.yml"))

  @@public_health_monitoring_actions = PublicHealthMonitoringActions.new(nil)
  @@public_health_monitoring_dashboard = PublicHealthMonitoringDashboard.new(nil)
  @@public_health_monitoring_history = PublicHealthMonitoringHistory.new(nil)
  @@public_health_monitoring_reports = PublicHealthMonitoringReports.new(nil)
  @@public_health_monitoring_utils = PublicHealthMonitoringUtils.new(nil)

  test "epis can only view and search for patients under their jurisdiction" do
    search_for_and_verify_patients_under_jurisdiction(USERS["state1_epi"], [3], [2, 6, 7], [4, 8], [5])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals1c1_epi"], [], [], [4], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals1c2_epi"], [], [6], [], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["state2_epi"], [], [11], [9, 10], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals2c3_epi"], [], [11], [], [])
    search_for_and_verify_patients_under_jurisdiction(USERS["locals2c4_epi"], [], [], [10], [])
  end
  
  test "perform monitoring actions" do
    update_monitoring_status(USERS["state1_epi"], PATIENTS["patient_2"], "Non-Reporting", "Closed", "Not Monitoring", "Completed Monitoring", "details")
  end

  test "update assigned jurisdiction" do
  end

  test "view, add, edit, and clear reports" do
  end

  test "add comment" do
  end

  test "export data to excel and csv" do
  end

  def search_for_and_verify_patients_under_jurisdiction(epi, symptomatic_patients, non_reporting_patients, asymptomatic_patients, closed_patients)
    @@public_health_monitoring_utils.login(epi)
    @@public_health_monitoring_dashboard.verify_patients_under_tab("Symptomatic", PATIENTS, symptomatic_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab("Non-Reporting", PATIENTS, non_reporting_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab("Asymptomatic", PATIENTS, asymptomatic_patients)
    @@public_health_monitoring_dashboard.verify_patients_under_tab("Closed", PATIENTS, closed_patients)
    @@public_health_monitoring_utils.logout
  end

  def update_monitoring_status(epi, patient, old_tab, new_tab, monitoring_status, status_change_reason, reasoning)
    @@public_health_monitoring_utils.login(epi)
    @@public_health_monitoring_dashboard.search_for_and_view_patient(old_tab, patient)
    @@public_health_monitoring_actions.update_monitoring_status(monitoring_status, status_change_reason, reasoning)
    @@public_health_monitoring_dashboard.return_to_dashboard
    @@public_health_monitoring_dashboard.verify_patient_under_tab(new_tab, patient)
    @@public_health_monitoring_utils.logout
  end

end
