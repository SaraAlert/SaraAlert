# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'lib/assessment/form'
require_relative 'lib/monitoree_enrollment/form'
require_relative 'lib/monitoree_enrollment/helper'
require_relative 'lib/monitoree_enrollment/dashboard_verifier'
require_relative 'lib/public_health_monitoring/actions'
require_relative 'lib/public_health_monitoring/dashboard'
require_relative 'lib/public_health_monitoring/dashboard_verifier'
require_relative 'lib/public_health_monitoring/history_verifier'
require_relative 'lib/public_health_monitoring/monitoree_page'
require_relative 'lib/public_health_monitoring/monitoree_page_verifier'
require_relative 'lib/public_health_monitoring/reports'
require_relative 'lib/public_health_monitoring/reports_verifier'
require_relative 'lib/system_test_utils'

class WorkflowTest < ApplicationSystemTestCase
  @@assessment_form = AssessmentForm.new(nil)
  @@monitoree_enrollment_form = MonitoreeEnrollmentForm.new(nil)
  @@monitoree_enrollment_helper = MonitoreeEnrollmentHelper.new(nil)
  @@monitoree_enrollment_dashboard_verifier = MonitoreeEnrollmentDashboardVerifier.new(nil)
  @@public_health_monitoring_actions = PublicHealthMonitoringActions.new(nil)
  @@public_health_monitoring_dashboard = PublicHealthMonitoringDashboard.new(nil)
  @@public_health_monitoring_dashboard_verifier = PublicHealthMonitoringDashboardVerifier.new(nil)
  @@public_health_monitoring_history_verifier = PublicHealthMonitoringHistoryVerifier.new(nil)
  @@public_health_monitoring_monitoree_page = PublicHealthMonitoringMonitoreePage.new(nil)
  @@public_health_monitoring_monitoree_page_verifier = PublicHealthMonitoringMonitoreePageVerifier.new(nil)
  @@public_health_monitoring_reports = PublicHealthMonitoringReports.new(nil)
  @@public_health_monitoring_reports_verifier = PublicHealthMonitoringReportsVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  ASSESSMENTS = @@system_test_utils.get_assessments
  MONITOREES = @@system_test_utils.get_monitorees

  test 'epi enroll monitoree, complete assessment, update monitoring actions, jurisdiction, workflow' do
    # enroll monitoree, should be asymptomatic
    enroller_user_label = 'state1_epi_enroller'
    monitoree_label = 'monitoree_3'
    @@monitoree_enrollment_helper.enroll_monitoree(enroller_user_label, monitoree_label, true)
    @@system_test_utils.login(enroller_user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('asymptomatic', monitoree_label)
    @@public_health_monitoring_reports_verifier.verify_current_status('asymptomatic')

    # add symptomatic report, should be symptomatic
    @@public_health_monitoring_reports.add_report(enroller_user_label, ASSESSMENTS['assessment_1'])
    @@public_health_monitoring_reports_verifier.verify_current_status('symptomatic')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('symptomatic', monitoree_label)

    # mark all reports as reviewed, should be symptomatic again
    @@public_health_monitoring_reports.mark_all_as_reviewed(enroller_user_label, 'reason', true)
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('asymptomatic', monitoree_label)

    # add PUI, should be listed under PUI tab
    @@public_health_monitoring_actions.update_latest_public_health_action(enroller_user_label, 'Recommended medical evaluation of symptoms', 'reason')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('pui', monitoree_label)

    # update assigned jurisdiction, should be transferred out of old jurisdiction and transferred into new one
    @@public_health_monitoring_actions.update_assigned_jurisdiction(enroller_user_label, 'USA, State 2', 'reason')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard_verifier.verify_monitoree_under_tab('transferred-out', monitoree_label)
    @@system_test_utils.logout
    @@system_test_utils.login('state2_epi')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('transferred-in', monitoree_label)
  end

  test 'enroller enroll monitoree, epi complete assessment' do
    # enroll monitoree
    enroller_user_label = 'state1_enroller'
    monitoree_label = 'monitoree_2'
    @@monitoree_enrollment_helper.enroll_monitoree(enroller_user_label, monitoree_label)

    # complete assessment
    epi_user_label = 'state1_epi'
    @@system_test_utils.login(epi_user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('asymptomatic', monitoree_label)
    @@public_health_monitoring_reports_verifier.verify_current_status('asymptomatic')
    @@assessment_form.complete_assessment(Patient.order(created_at: :desc).first, 'assessment_2')
    visit '/'
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('symptomatic', monitoree_label)
    @@public_health_monitoring_reports_verifier.verify_current_status('symptomatic')
    @@public_health_monitoring_reports_verifier.verify_new_report(ASSESSMENTS['assessment_2'])
  end

  test 'epi enroll monitoree with group member, edit parent jurisdiction and verify propogation' do
    # enroll monitoree and group member
    enroller_user_label = 'state2_enroller'
    monitoree_label = 'monitoree_3'
    group_member_label = 'monitoree_8'
    @@monitoree_enrollment_helper.enroll_group_member(enroller_user_label, monitoree_label, group_member_label)

    # edit parent jurisdiction but do not propagate to group member
    edited_monitoree_without_propogation_label = 'monitoree_13'
    @@system_test_utils.login(enroller_user_label)
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(MONITOREES[monitoree_label], false, false)
    @@monitoree_enrollment_form.edit_monitoree_info(MONITOREES[edited_monitoree_without_propogation_label])
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    new_jurisdiction = MONITOREES[edited_monitoree_without_propogation_label]['potential_exposure_info']['jurisdiction_id']
    assert page.has_content?(new_jurisdiction)
    @@system_test_utils.logout

    # parent should have been transferred but not child, verify transfers and history
    new_jurisdiction_epi_user_label = 'locals2c3_epi'
    @@system_test_utils.login(new_jurisdiction_epi_user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('transferred-in', monitoree_label)
    @@public_health_monitoring_history_verifier.verify_assigned_jurisdiction(enroller_user_label, new_jurisdiction, '')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard.search_for_monitoree(group_member_label)
    assert page.has_no_content?(MONITOREES[group_member_label]['identification']['first_name'])
    @@system_test_utils.logout

    # edit parent jurisdiction and propagate to group member
    edited_monitoree_with_propogation_label = 'monitoree_14'
    @@system_test_utils.login(enroller_user_label)
    @@monitoree_enrollment_dashboard_verifier.verify_monitoree_info_on_dashboard(MONITOREES[monitoree_label], false, false)
    @@monitoree_enrollment_form.edit_monitoree_info(MONITOREES[edited_monitoree_with_propogation_label])
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    newer_jurisdiction = MONITOREES[edited_monitoree_with_propogation_label]['potential_exposure_info']['jurisdiction_id']
    assert page.has_content?(newer_jurisdiction)
    click_on @@system_test_utils.get_displayed_name(MONITOREES[group_member_label])
    assert page.has_content?(newer_jurisdiction)
    @@system_test_utils.logout

    # both parent and child should have been transferred, verify transfer and history
    newer_jurisdiction_epi_user_label = 'locals2c4_epi'
    @@system_test_utils.login(newer_jurisdiction_epi_user_label)
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('transferred-in', monitoree_label)
    @@public_health_monitoring_history_verifier.verify_assigned_jurisdiction(enroller_user_label, newer_jurisdiction, '')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_monitoring_dashboard.search_for_and_view_monitoree('transferred-in', group_member_label)
    @@public_health_monitoring_history_verifier.verify_assigned_jurisdiction(enroller_user_label, newer_jurisdiction, '')
    @@system_test_utils.logout
  end
end
