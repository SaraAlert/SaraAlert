# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'lib/assessment/form'
require_relative 'lib/monitoree_enrollment/helper'
require_relative 'lib/public_health_monitoring/actions'
require_relative 'lib/public_health_monitoring/dashboard'
require_relative 'lib/public_health_monitoring/dashboard_verifier'
require_relative 'lib/public_health_monitoring/monitoree_page'
require_relative 'lib/public_health_monitoring/monitoree_page_verifier'
require_relative 'lib/public_health_monitoring/reports'
require_relative 'lib/public_health_monitoring/reports_verifier'
require_relative 'lib/system_test_utils'

class WorkflowTest < ApplicationSystemTestCase
  @@assessment_form = AssessmentForm.new(nil)
  @@monitoree_enrollment_helper = MonitoreeEnrollmentHelper.new(nil)
  @@public_health_monitoring_actions = PublicHealthMonitoringActions.new(nil)
  @@public_health_monitoring_dashboard = PublicHealthMonitoringDashboard.new(nil)
  @@public_health_monitoring_reports = PublicHealthMonitoringReports.new(nil)
  @@public_health_monitoring_monitoree_page = PublicHealthMonitoringMonitoreePage.new(nil)
  @@public_health_monitoring_dashboard_verifier = PublicHealthMonitoringDashboardVerifier.new(nil)
  @@public_health_monitoring_monitoree_page_verifier = PublicHealthMonitoringMonitoreePageVerifier.new(nil)
  @@public_health_monitoring_reports_verifier = PublicHealthMonitoringReportsVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  ASSESSMENTS = @@system_test_utils.get_assessments

  test 'epi enroll monitoree, complete assessment, update monitoring actions, jurisdiction, workflow' do
    user_name = 'state1_epi_enroller'
    monitoree_key = 'monitoree_3'
    @@monitoree_enrollment_helper.enroll_monitoree(user_name, monitoree_key, true)
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('asymptomatic', monitoree_key)
    @@public_health_monitoring_reports_verifier.verify_current_status('asymptomatic')
    @@public_health_monitoring_reports.add_report(user_name, ASSESSMENTS['assessment_1'])
    @@public_health_monitoring_reports_verifier.verify_current_status('symptomatic')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('symptomatic', monitoree_key)
    @@public_health_monitoring_reports.mark_all_as_reviewed(user_name, 'reason', true)
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('asymptomatic', monitoree_key)
    @@public_health_monitoring_actions.update_latest_public_health_action(user_name, 'Recommended medical evaluation of symptoms', 'reason')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('pui', monitoree_key)
    @@public_health_monitoring_actions.update_assigned_jurisdiction(user_name, 'USA, State 2', 'reason')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard_verifier.verify_monitoree_under_tab('transferred-out', monitoree_key)
    @@system_test_utils.logout
    @@system_test_utils.login('state2_epi')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('transferred-in', monitoree_key)
    @@public_health_monitoring_actions.update_current_workflow(user_name, 'Isolation', 'reason')
    @@system_test_utils.return_to_dashboard('isolation')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('all', monitoree_key)
    @@public_health_monitoring_actions.update_current_workflow(user_name, 'Exposure', 'reason')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard_verifier.verify_monitoree_under_tab('transferred-in', monitoree_key)
    @@system_test_utils.logout
  end

  test 'enroller enroll monitoree, monitoree complete assessment, epi view monitoree' do
    enroller_user_name = 'state1_enroller'
    epi_user_name = 'state1_epi'
    monitoree_key = 'monitoree_2'
    @@monitoree_enrollment_helper.enroll_monitoree(enroller_user_name, monitoree_key)
    @@system_test_utils.logout
    @@system_test_utils.login(epi_user_name)
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('asymptomatic', monitoree_key)
    @@public_health_monitoring_reports_verifier.verify_current_status('asymptomatic')
    @@assessment_form.complete_assessment(Patient.order(created_at: :desc).first, 'assessment_2')
    visit '/'
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('symptomatic', monitoree_key)
    @@public_health_monitoring_reports_verifier.verify_current_status('symptomatic')
    @@public_health_monitoring_reports_verifier.verify_new_report(ASSESSMENTS['assessment_2'])
  end
end
