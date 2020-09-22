# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'export_verifier'
require_relative 'import_verifier'
require_relative '../../../lib/system_test_utils'

class PublicHealthDashboard < ApplicationSystemTestCase
  @@public_health_export_verifier = PublicHealthMonitoringExportVerifier.new(nil)
  @@public_health_import_verifier = PublicHealthMonitoringImportVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  PATIENTS = @@system_test_utils.patients
  MONITOREES = @@system_test_utils.monitorees

  def search_for_and_view_patient(tab, patient_label)
    @@system_test_utils.go_to_tab(tab)
    fill_in 'search', with: PATIENTS[patient_label]['last_name']
    click_on @@system_test_utils.get_patient_display_name(patient_label)
  end

  def search_for_and_view_monitoree(tab, monitoree_label)
    @@system_test_utils.go_to_tab(tab)
    fill_in 'search', with: MONITOREES[monitoree_label]['identification']['last_name']
    click_on @@system_test_utils.get_monitoree_display_name(monitoree_label)
  end

  def search_for_monitoree(monitoree_label)
    fill_in 'search', with: MONITOREES[monitoree_label]['identification']['last_name']
  end

  def export_line_list_csv(user_label, workflow, action)
    start_export(workflow, "Line list CSV (#{workflow})", action)
    @@public_health_export_verifier.verify_line_list_csv(user_label, workflow) if action == :export
  end

  def export_sara_alert_format(user_label, workflow, action)
    start_export(workflow, "Sara Alert Format (#{workflow})", action)
    @@public_health_export_verifier.verify_sara_alert_format(user_label, workflow) if action == :export
  end

  def export_excel_purge_eligible_monitorees(user_label, workflow, action)
    start_export(workflow, 'Excel Export For Purge-Eligible Monitorees', action)
    @@public_health_export_verifier.verify_excel_purge_eligible_monitorees(user_label) if action == :export
  end

  def export_excel_all_monitorees(user_label, workflow, action)
    start_export(workflow, 'Excel Export For All Monitorees', action)
    @@public_health_export_verifier.verify_excel_all_monitorees(user_label) if action == :export
  end

  def export_excel_single_monitoree(patient_label)
    search_for_and_view_patient('all', patient_label)
    click_on 'Download Excel Export'
    @@public_health_export_verifier.verify_excel_single_monitoree(patient_label.split('_')[1].to_i)
  end

  def start_export(workflow, export_type, action)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Export'
    click_on export_type
    if action == :export
      click_on 'Start Export'
    else
      click_on 'Cancel'
    end
  end

  # rubocop:disable Metrics/ParameterLists
  def import_epi_x(jurisdiction_id, workflow, file_name, validity, rejects, accept_duplicates)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Import'
    find('a', text: "Epi-X (#{workflow})").click
    page.attach_file(file_fixture(file_name))
    click_on 'Upload'
    case validity
    when :valid
      @@public_health_import_verifier.verify_epi_x_import_page(jurisdiction_id, workflow, file_name)
      select_monitorees_to_import(rejects, accept_duplicates)
      @@public_health_import_verifier.verify_epi_x_import_data(jurisdiction_id, workflow, file_name, rejects, accept_duplicates)
    when :invalid_file
      assert_content('Please make sure that your import file is a .xlsx file.')
      find('.modal-header').find('.close').click
    when :invalid_format
      assert_content('Please make sure that .xlsx import file is formatted in accordance with the formatting guidance.')
      find('.modal-header').find('.close').click
    when :invalid_headers
      assert_content('Please make sure to use the latest Epi-X format.')
      find('.modal-header').find('.close').click
    when :invalid_monitorees
      assert_content('File must contain at least one monitoree to import')
      find('.modal-header').find('.close').click
    when :invalid_fields
      @@public_health_import_verifier.verify_epi_x_field_validation(jurisdiction_id, workflow, file_name)
      find('.modal-header').find('.close').click
    end
  end

  def import_sara_alert_format(jurisdiction_id, workflow, file_name, validity, rejects, accept_duplicates)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Import'
    find('a', text: "Sara Alert Format (#{workflow})").click
    page.attach_file(file_fixture(file_name))
    click_on 'Upload'
    case validity
    when :valid
      @@public_health_import_verifier.verify_sara_alert_format_import_page(jurisdiction_id, workflow, file_name)
      select_monitorees_to_import(rejects, accept_duplicates)
      @@public_health_import_verifier.verify_sara_alert_format_import_data(jurisdiction_id, workflow, file_name, rejects, accept_duplicates)
    when :invalid_file
      assert_content('Please make sure that your import file is a .xlsx file.')
      find('.modal-header').find('.close').click
    when :invalid_format
      assert_content('Please make sure that .xlsx import file is formatted in accordance with the formatting guidance.')
      find('.modal-header').find('.close').click
    when :invalid_headers
      assert_content('Please make sure to use the latest format specified by the Sara Alert Format guidance doc.')
      find('.modal-header').find('.close').click
    when :invalid_monitorees
      assert_content('File must contain at least one monitoree to import')
      find('.modal-header').find('.close').click
    when :invalid_fields
      @@public_health_import_verifier.verify_sara_alert_format_field_validation(jurisdiction_id, workflow, file_name)
      find('.modal-header').find('.close').click
    end
  end
  # rubocop:enable Metrics/ParameterLists

  def import_and_cancel(workflow, file_name, file_type)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Import'
    find('a', text: "#{file_type} (#{workflow})").click
    page.attach_file(file_fixture(file_name))
    click_on 'Upload'
    sleep(0.5) # wait for import modal to open
    find('button.close').click
    assert_content('You are about to cancel the import process. Are you sure you want to do this?')
    click_on 'Return to Import'
    sleep(0.5) # wait for cancel import modal to close
    page.find('body').send_keys :escape
    assert_content('You are about to cancel the import process. Are you sure you want to do this?')
    click_on 'Proceed to Cancel'
    sleep(0.5) # wait for import modal to close
    assert page.has_no_content?("Import #{file_type}")
    click_on 'Import'
    find('a', text: file_type).click
    page.attach_file(file_fixture(file_name))
    click_on 'Upload'
    sleep(0.5) # wait for import modal to open
    find('.modal-body').find('div.card-body', match: :first).find('button', text: 'Accept').click
    sleep(0.5) # wait for patient to be accepted
    find('button.close').click
    assert_content('You are about to stop the import process. Are you sure you want to do this?')
    click_on 'Return to Import'
    sleep(0.5) # wait for cancel import modal to close
    page.find('body').send_keys :escape
    assert_content('You are about to stop the import process. Are you sure you want to do this?')
    click_on 'Proceed to Stop'
    sleep(0.5) # wait for import modal to close
    assert page.has_no_content?("Import #{file_type}")
  end

  def download_sara_alert_format_guidance(workflow)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Import'
    find('a', text: "Sara Alert Format (#{workflow})").click
    click_on 'Download formatting guidance'
    @@public_health_export_verifier.verify_sara_alert_format_guidance
    @@system_test_utils.wait_for_modal_animation
    click_on(class: 'close')
    @@system_test_utils.wait_for_modal_animation
  end

  def select_monitorees_to_import(rejects, accept_duplicates)
    if rejects.nil?
      click_on 'Import All'
      find(:css, '.confirm-dialog').find(:css, '.form-check-input').set(true) if accept_duplicates
      click_on 'OK'
    else
      find('.modal-body').all('div.card-body').each_with_index do |card, index|
        if rejects.include?(index)
          card.find('button', text: 'Reject').click
        else
          card.find('button', text: 'Accept').click
        end
        sleep(0.01) # wait for UI to update after accepting or rejecting monitoree
      end
    end
  end

  def select_monitorees_for_bulk_edit(workflow, tab, patient_labels)
    click_on 'Isolation Monitoring' if workflow == :isolation
    @@system_test_utils.go_to_tab(tab)
    @@system_test_utils.go_to_tab(tab)
    patient_labels.each { |patient| check_patient(patient) }
  end

  def check_patient(patient_label)
    find_by_id(PATIENTS[patient_label]['id'].to_s).find('input').click
  end

  def bulk_edit_update_case_status(workflow, case_status, next_step, apply_to_group)
    click_on 'Actions'
    click_on 'Update Case Status'
    select(case_status, from: 'case_status')
    select(next_step, from: 'follow_up') if workflow != :isolation && %w[Confirmed Probable].include?(case_status)
    find_by_id('apply_to_group', { visible: :all }).check({ allow_label_click: true }) if apply_to_group
    click_on 'Submit'
    go_to_other_workflow(workflow) if next_step != 'End Monitoring'
  end

  def bulk_edit_close_records(monitoring_reason, reasoning, apply_to_group)
    click_on 'Actions'
    click_on 'Close Records'
    select(monitoring_reason, from: 'monitoring_reason') unless monitoring_reason.blank?
    fill_in 'reasoning', with: reasoning
    find_by_id('apply_to_group', { visible: :all }).check({ allow_label_click: true }) if apply_to_group
    click_on 'Submit'
  end

  def go_to_other_workflow(workflow)
    click_on 'Isolation Monitoring' if workflow == :exposure

    click_on 'Exposure Monitoring' if workflow == :isolation
  end
end
