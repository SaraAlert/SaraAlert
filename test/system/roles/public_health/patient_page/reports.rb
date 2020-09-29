# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'history_verifier'
require_relative 'reports_verifier'
require_relative '../../monitoree/assessment/form'
require_relative '../../../lib/system_test_utils'

class PublicHealthPatientPageReports < ApplicationSystemTestCase
  @@public_health_patient_page_history_verifier = PublicHealthPatientPageHistoryVerifier.new(nil)
  @@public_health_patient_page_reports_verifier = PublicHealthPatientPageReportsVerifier.new(nil)
  @@assessment_form = AssessmentForm.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def add_report(user_label, assessment)
    click_on 'Add New Report'
    @@assessment_form.submit_assessment(assessment['symptoms'])
    @@public_health_patient_page_reports_verifier.verify_add_report(user_label, assessment)
    search_for_report(user_label)
    @@public_health_patient_page_history_verifier.verify_add_report(user_label)
  end

  def edit_report(user_label, assessment_id, assessment, submit: true)
    search_for_report(assessment_id)
    find('button', class: 'a-dropdown').click
    click_on 'Edit'
    @@assessment_form.submit_assessment(assessment['symptoms'])
    if submit
      click_on 'OK'
      search_for_report(assessment_id)
      @@public_health_patient_page_reports_verifier.verify_edit_report(user_label, assessment)
      @@public_health_patient_page_history_verifier.verify_edit_report(user_label)
    else
      click_on 'Cancel'
      assert page.has_content?('Daily Self-Report'), @@system_test_utils.get_err_msg('Edit report', 'title', 'existent')
      find('button', class: 'close').click
    end
  end

  def add_note_to_report(user_label, assessment_id, note, submit: true)
    search_for_report(assessment_id)
    find('button', class: 'a-dropdown').click
    click_on 'Add Note'
    fill_in 'comment', with: note
    if submit
      click_on 'Submit'
      @@public_health_patient_page_history_verifier.verify_add_note_to_report(user_label, assessment_id, note)
    else
      click_on 'Cancel'
    end
  end

  def mark_all_as_reviewed(user_label, reasoning, submit: true)
    click_on 'Mark All As Reviewed'
    fill_in 'reasoning', with: reasoning
    if submit
      click_on 'Submit'
      @@public_health_patient_page_history_verifier.verify_mark_all_as_reviewed(user_label, reasoning)
    else
      click_on 'Cancel'
    end
    @@system_test_utils.wait_for_modal_animation
  end

  def pause_notifications(user_label, submit: true)
    pause_notifications = find('#pause_notifications').text == 'Resume Notifications'
    find('#pause_notifications').click
    if submit
      click_on 'OK'
      @@public_health_patient_page_reports_verifier.verify_pause_notifications(!pause_notifications)
      @@public_health_patient_page_history_verifier.verify_pause_notifications(user_label, !pause_notifications)
    else
      click_on 'Cancel'
      @@public_health_patient_page_reports_verifier.verify_pause_notifications(pause_notifications)
    end
  end

  def search_for_report(query)
    fill_in 'Search Reports:', with: query
  end
end
