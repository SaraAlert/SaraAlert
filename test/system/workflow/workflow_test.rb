# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCaseWorkflow'

require_relative '../roles/enroller/enroller_test_helper'
require_relative '../roles/enroller/enrollment/form'
require_relative '../roles/enroller/dashboard/dashboard_verifier'
require_relative '../roles/monitoree/assessment/form'
require_relative '../roles/public_health/dashboard/dashboard'
require_relative '../roles/public_health/dashboard/dashboard_verifier'
require_relative '../roles/public_health/patient_page/actions'
require_relative '../roles/public_health/patient_page/history_verifier'
require_relative '../roles/public_health/patient_page/patient_page'
require_relative '../roles/public_health/patient_page/patient_page_verifier'
require_relative '../roles/public_health/patient_page/reports'
require_relative '../roles/public_health/patient_page/reports_verifier'
require_relative '../lib/system_test_utils'

class WorkflowTest < ApplicationSystemTestCase
  @@enroller_test_helper = EnrollerTestHelper.new(nil)
  @@enrollment_form = EnrollmentForm.new(nil)
  @@enroller_dashboard_verifier = EnrollerDashboardVerifier.new(nil)
  @@assessment_form = AssessmentForm.new(nil)
  @@public_health_dashboard = PublicHealthDashboard.new(nil)
  @@public_health_dashboard_verifier = PublicHealthDashboardVerifier.new(nil)
  @@public_health_patient_page = PublicHealthPatientPage.new(nil)
  @@public_health_patient_page_actions = PublicHealthPatientPageActions.new(nil)
  @@public_health_patient_page_history_verifier = PublicHealthPatientPageHistoryVerifier.new(nil)
  @@public_health_patient_page_verifier = PublicHealthPatientPageVerifier.new(nil)
  @@public_health_patient_page_reports = PublicHealthPatientPageReports.new(nil)
  @@public_health_patient_page_reports_verifier = PublicHealthPatientPageReportsVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  ASSESSMENTS = @@system_test_utils.assessments
  MONITOREES = @@system_test_utils.monitorees

  test 'epi enroll monitoree, complete assessment, update monitoring actions, jurisdiction, workflow' do
    # enroll monitoree, should be asymptomatic
    epi_enroller_user_label = 'state1_epi_enroller'
    monitoree_label = 'monitoree_3'
    @@enroller_test_helper.enroll_monitoree(epi_enroller_user_label, monitoree_label, is_epi: true)
    @@system_test_utils.login(epi_enroller_user_label)
    @@public_health_dashboard.search_for_and_view_monitoree('asymptomatic', monitoree_label)
    @@public_health_patient_page_reports_verifier.verify_current_status('asymptomatic')

    # add symptomatic report, should be symptomatic
    @@public_health_patient_page_reports.add_report(epi_enroller_user_label, ASSESSMENTS['assessment_1'])
    @@public_health_patient_page_reports_verifier.verify_current_status('symptomatic')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_dashboard.search_for_and_view_monitoree('symptomatic', monitoree_label)

    # mark all reports as reviewed, should be symptomatic again
    @@public_health_patient_page_reports.mark_all_as_reviewed(epi_enroller_user_label, 'reason', submit: true)
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_dashboard.search_for_and_view_monitoree('asymptomatic', monitoree_label)

    # add PUI, should be listed under PUI tab
    @@public_health_patient_page_actions.update_latest_public_health_action(epi_enroller_user_label, monitoree_label,
                                                                            'Recommended medical evaluation of symptoms', 'reason')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_dashboard.search_for_and_view_monitoree('pui', monitoree_label)

    # update assigned jurisdiction, should be transferred out of old jurisdiction and transferred into new one
    @@public_health_patient_page_actions.update_assigned_jurisdiction(epi_enroller_user_label, monitoree_label, 'USA, State 2', 'reason',
                                                                      valid_jurisdiction: true, under_hierarchy: false)
    @@public_health_dashboard_verifier.verify_monitoree_under_tab('transferred_out', monitoree_label)
    @@system_test_utils.logout
    @@system_test_utils.login('state2_epi')
    @@public_health_dashboard.search_for_and_view_monitoree('transferred_in', monitoree_label)
  end

  test 'enroller enroll monitoree, epi complete assessment' do
    # enroll monitoree
    enroller_user_label = 'state1_enroller'
    monitoree_label = 'monitoree_2'
    @@enroller_test_helper.enroll_monitoree(enroller_user_label, monitoree_label)

    # complete assessment
    epi_user_label = 'state1_epi'
    @@system_test_utils.login(epi_user_label)
    @@public_health_dashboard.search_for_and_view_monitoree('asymptomatic', monitoree_label)
    @@public_health_patient_page_reports_verifier.verify_current_status('asymptomatic')
    @@assessment_form.complete_assessment(Patient.order(created_at: :desc).first, 'assessment_2')
    visit '/'
    @@public_health_dashboard.search_for_and_view_monitoree('symptomatic', monitoree_label)
    @@public_health_patient_page_reports_verifier.verify_current_status('symptomatic')
    @@public_health_patient_page_reports_verifier.verify_new_report(ASSESSMENTS['assessment_2'])
  end

  test 'epi enroll monitoree with group member, edit parent jurisdiction and verify propogation' do
    # enroll monitoree and group member
    enroller_user_label = 'state2_enroller'
    monitoree_label = 'monitoree_3'
    group_member_label = 'monitoree_8'
    @@enroller_test_helper.enroll_group_member(enroller_user_label, monitoree_label, group_member_label)

    # edit parent jurisdiction but do not propagate to group member
    edited_monitoree_without_propogation_label = 'monitoree_13'
    @@system_test_utils.login(enroller_user_label)
    @@enroller_dashboard_verifier.verify_monitoree_info_on_dashboard(MONITOREES[monitoree_label], is_epi: false, go_back: false)
    @@enrollment_form.edit_monitoree_info(MONITOREES[edited_monitoree_without_propogation_label])
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission
    new_jurisdiction = MONITOREES[edited_monitoree_without_propogation_label]['potential_exposure_info']['jurisdiction_id']
    assert page.has_content?(new_jurisdiction)
    @@system_test_utils.logout

    # parent should have been transferred but not child, verify transfers and history
    new_jurisdiction_epi_user_label = 'locals2c3_epi'
    @@system_test_utils.login(new_jurisdiction_epi_user_label)
    @@public_health_dashboard.search_for_and_view_monitoree('transferred_in', monitoree_label)
    @@public_health_patient_page_history_verifier.verify_assigned_jurisdiction(enroller_user_label, new_jurisdiction, '')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_dashboard.search_for_monitoree(group_member_label)
    assert page.has_no_content?(MONITOREES[group_member_label]['identification']['first_name'])
    @@system_test_utils.logout

    # edit parent jurisdiction and propagate to group member
    edited_monitoree_with_propogation_label = 'monitoree_14'
    @@system_test_utils.login(enroller_user_label)
    @@enroller_dashboard_verifier.verify_monitoree_info_on_dashboard(MONITOREES[monitoree_label], is_epi: false, go_back: false)
    @@enrollment_form.edit_monitoree_info(MONITOREES[edited_monitoree_with_propogation_label])
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
    @@public_health_dashboard.search_for_and_view_monitoree('transferred_in', monitoree_label)
    @@public_health_patient_page_history_verifier.verify_assigned_jurisdiction(enroller_user_label, newer_jurisdiction, '')
    @@system_test_utils.return_to_dashboard('exposure')
    @@public_health_dashboard.search_for_and_view_monitoree('transferred_in', group_member_label)
    @@public_health_patient_page_history_verifier.verify_assigned_jurisdiction(enroller_user_label, newer_jurisdiction, '')
    @@system_test_utils.logout
  end

  test 'epi enroll monitoree with group member, edit parent assigned user and verify propagation' do
    # enroll monitoree and group member
    epi_enroller_user_label = 'state1_epi_enroller'
    monitoree_label = 'monitoree_3'
    group_member_label = 'monitoree_8'
    @@enroller_test_helper.enroll_group_member(epi_enroller_user_label, monitoree_label, group_member_label, is_epi: true)

    # edit parent assigned user but do not propagate to group member
    @@system_test_utils.login(epi_enroller_user_label)
    @@public_health_dashboard.search_for_and_view_monitoree('all', monitoree_label)
    edited_monitoree_without_propogation_label = 'monitoree_15'
    @@enrollment_form.edit_monitoree_info(MONITOREES[edited_monitoree_without_propogation_label])
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission

    # parent should have been updated but not child, verify history
    old_assigned_user = MONITOREES[monitoree_label]['potential_exposure_info']['assigned_user'] || ''
    new_assigned_user = MONITOREES[edited_monitoree_without_propogation_label]['potential_exposure_info']['assigned_user'] || ''
    assert page.has_content?(new_assigned_user)
    @@public_health_patient_page_history_verifier.verify_assigned_user(epi_enroller_user_label, new_assigned_user, '')
    click_on @@system_test_utils.get_displayed_name(MONITOREES[group_member_label])
    assert page.has_no_content?("User changed assigned user from \"#{old_assigned_user}\" to \"#{new_assigned_user}\"")

    # edit parent assigned user and propagate to group member
    edited_monitoree_with_propogation_label = 'monitoree_16'
    click_on 'Click here to view that monitoree'
    @@enrollment_form.edit_monitoree_info(MONITOREES[edited_monitoree_with_propogation_label])
    click_on 'Finish'
    @@system_test_utils.wait_for_enrollment_submission

    # parent and child should have been updated, verify history
    newer_assigned_user = MONITOREES[edited_monitoree_with_propogation_label]['potential_exposure_info']['assigned_user'] || ''
    assert page.has_content?(newer_assigned_user)
    @@public_health_patient_page_history_verifier.verify_assigned_user(epi_enroller_user_label, newer_assigned_user, '')
    click_on @@system_test_utils.get_displayed_name(MONITOREES[group_member_label])
    assert page.has_content?(newer_assigned_user)
    @@public_health_patient_page_history_verifier.verify_assigned_user(epi_enroller_user_label, newer_assigned_user, '')
    @@system_test_utils.logout
  end
end
