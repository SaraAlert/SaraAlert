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

  EPIS_HOME_PAGE_URL = "/public_health"

  @@public_health_monitoring_actions = PublicHealthMonitoringActions.new(nil)
  @@public_health_monitoring_dashboard = PublicHealthMonitoringDashboard.new(nil)
  @@public_health_monitoring_history = PublicHealthMonitoringHistory.new(nil)
  @@public_health_monitoring_reports = PublicHealthMonitoringReports.new(nil)
  @@public_health_monitoring_utils = PublicHealthMonitoringUtils.new(nil)

  test "search for exisitng patients" do
    @@public_health_monitoring_utils.login(USERS["state1_epi"], EPIS_HOME_PAGE_URL)
    @@public_health_monitoring_dashboard.select_tab("Closed")
    @@public_health_monitoring_dashboard.search_and_verify_patient_info(PATIENTS["patient_5"])
    @@public_health_monitoring_dashboard.select_tab("Asymptomatic")
    # @@public_health_monitoring_dashboard.search_and_verify_patient_info(PATIENTS["patient_4"]) # test currently depends on today's date
    # @@public_health_monitoring_dashboard.search_and_verify_patient_info(PATIENTS["patient_7"]) # test currently depends on today's date
    @@public_health_monitoring_dashboard.select_tab("Non-Reporting")
    @@public_health_monitoring_dashboard.search_and_verify_patient_info(PATIENTS["patient_2"])
    @@public_health_monitoring_dashboard.search_and_verify_patient_info(PATIENTS["patient_6"])
    @@public_health_monitoring_dashboard.search_and_verify_patient_info(PATIENTS["patient_8"])
    @@public_health_monitoring_dashboard.select_tab("Symptomatic")
    # @@public_health_monitoring_dashboard.search_and_verify_patient_info(PATIENTS["patient_3"]) # test currently depends on today's date
  end
  
  test "update monitoring status" do
  end

  test "update assigned jurisdiction" do
  end

  test "view, add, edit, and clear reports" do
  end

  test "add comment" do
  end

  test "export data to excel and csv" do
  end

end
