# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'export_verifier'
require_relative 'import_verifier'
require_relative '../../../lib/system_test_utils'

class PublicHealthDashboard < ApplicationSystemTestCase
  @@public_health_export_verifier = PublicHealthMonitoringExportVerifier.new(nil)
  @@public_health_import_verifier = PublicHealthMonitoringImportVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  PATIENTS = SystemTestUtils::PATIENTS
  MONITOREES = SystemTestUtils::MONITOREES

  def search_for_and_view_patient(tab, patient_label)
    @@system_test_utils.go_to_tab(tab)
    fill_in 'search', with: PATIENTS[patient_label]['last_name']
    click_on @@system_test_utils.get_patient_display_name(patient_label)
  end

  def search_for_and_view_monitoree(tab, monitoree_label)
    sleep(0.5)
    @@system_test_utils.go_to_tab(tab)
    fill_in 'search', with: MONITOREES[monitoree_label]['identification']['last_name']
    click_on @@system_test_utils.get_monitoree_display_name(monitoree_label)
  end

  def search_for_monitoree(monitoree_label)
    fill_in 'search', with: MONITOREES[monitoree_label]['identification']['last_name']
  end

  def export_csv_linelist(user_label, workflow, action)
    start_export(workflow, "Line list CSV (#{workflow})", action)
    @@public_health_export_verifier.verify_csv_linelist(user_label, workflow) if action == :export
  end

  def export_sara_alert_format(user_label, workflow, action)
    start_export(workflow, "Sara Alert Format (#{workflow})", action)
    @@public_health_export_verifier.verify_sara_alert_format(user_label, workflow) if action == :export
  end

  def export_full_history_patients(user_label, workflow, action, scope)
    start_export(workflow, "Excel Export For #{scope == :purgeable ? 'Purge-Eligible' : 'All'} Monitorees", action)
    @@public_health_export_verifier.verify_full_history_patients(user_label, scope) if action == :export
  end

  def start_export(workflow, export_type, action)
    find("##{workflow}-nav-btn").click if workflow.present?
    click_on 'Export'
    click_on export_type
    click_on action == :export ? 'Start Export' : 'Cancel'
  end

  def export_full_history_patient(patient_label)
    search_for_and_view_patient('all', patient_label)
    click_on 'Download Excel Export'
    @@public_health_export_verifier.verify_full_history_patient(patient_label.split('_')[1].to_i)
  end

  def export_custom(user_label, settings)
    find("##{settings[:workflow]}-nav-btn").click if settings[:workflow].present?
    @@system_test_utils.go_to_tab(settings[:tab]) if settings[:tab].present?

    click_on 'Export'
    click_on settings[:preset] || 'Custom Format...'

    # Choose which records to export
    choose "select-monitoree-records-#{settings[:records]}" if settings[:records].present?

    # Expand trees for selection
    settings[:data]&.each_value do |data_type|
      data_type[:expanded]&.each do |label|
        find('span', class: 'rct-title', text: label).first(:xpath, '..//..//button').click
      end
    end

    # Choose which elements to export
    settings[:data]&.each do |data_type, config|
      # only find headers under data type section to avoid ambiguous matches (ex: Sara Alert ID)
      section = find('span', class: 'rct-title', text: ImportExportConstants::CUSTOM_EXPORT_OPTIONS[data_type][:nodes][0][:label]).first(:xpath, '..//..//..')
      config[:selected]&.each do |label|
        section.find('span', class: 'rct-title', text: label).click
      end
    end

    # Provide optional custom export format name
    fill_in 'preset', with: settings[:name] if settings[:name].present?

    # Save, update, or delete preset
    settings[:actions]&.each do |action|
      click_on "custom-export-action-#{action}"
      sleep(1)
    end

    # Verify preset
    @@public_health_export_verifier.verify_preset(user_label, settings) if settings[:actions]&.include?(:save)

    # Start or cancel export
    click_on 'Start Export' if settings[:confirm] == :start
    click_on 'Cancel' if settings[:confirm] == :cancel

    # Verify export
    @@public_health_export_verifier.verify_custom(user_label, settings) if settings[:actions]&.include?(:export) && settings[:confirm] == :start
  end

  def import_and_verify(import_format, jurisdiction, workflow, file_name, validity, rejects, accept_duplicates)
    find("##{workflow}-nav-btn").click if workflow.present?
    click_on 'Import'
    find("#import-#{import_format}").click
    page.attach_file(file_fixture(file_name))
    click_on 'Upload'
    @@public_health_import_verifier.verify_import(import_format, jurisdiction, workflow, file_name, rejects, accept_duplicates) if validity == :valid
    @@public_health_import_verifier.verify_invalid_file_error(import_format) if validity == :invalid_file
    @@public_health_import_verifier.verify_invalid_format_error(import_format) if validity == :invalid_format
    @@public_health_import_verifier.verify_invalid_headers_error(import_format) if validity == :invalid_headers
    @@public_health_import_verifier.verify_invalid_monitorees_error if validity == :invalid_monitorees
    @@public_health_import_verifier.verify_invalid_fields_error(import_format, jurisdiction, workflow, file_name) if validity == :invalid_fields
    sleep(0.5) && find('.modal-header').find('.close').click unless validity == :valid
  end

  def import_sara_alert_format_exposure_with_continuous_exposure(file_name, jurisdiction, validity, rejects,
                                                                 accept_duplicates, cancel_import)
    click_on WORKFLOW_CLICK_MAP[:exposure]
    click_on 'Import'
    find('a', text: 'Sara Alert Format (exposure)').click
    page.attach_file(file_fixture(file_name))
    click_on 'Upload'
    sleep(1) # wait for import modal to open

    case validity
    when :valid
      assert_content('Your import contains one or more monitorees with Continuous Exposure enabled')
      if cancel_import
        click_on 'Cancel Import'

        sleep(0.75) # wait for import modal to close
        assert page.has_no_content?('Import Sara Alert Format')
      else
        click_on 'Continue'

        @@public_health_import_verifier.verify_sara_alert_format_import_page(jurisdiction, :exposure, file_name)
        select_monitorees_to_import(rejects, accept_duplicates)
        @@public_health_import_verifier.verify_sara_alert_format_import_data(
          jurisdiction, :exposure, file_name, rejects, accept_duplicates
        )
      end
    when :invalid_last_date_of_exposure
      assert_content('Monitorees may be imported either with a Last Date of Exposure value or Continuous Exposure ' \
                'set to \'true.\'')
    end
    sleep(0.5) && find('.modal-header').find('.close').click unless validity == :valid
  end

  def import_and_cancel(workflow, file_name, file_type)
    find("##{workflow}-nav-btn").click if workflow.present?
    click_on 'Import'
    find('a', text: "#{file_type} (#{workflow})").click
    page.attach_file(file_fixture(file_name))
    click_on 'Upload'
    sleep(1) # wait for import modal to open
    find('button.close').click
    assert_content('You are about to cancel the import process. Are you sure you want to do this?')
    click_on 'Return to Import'
    sleep(0.75) # wait for cancel import modal to close
    page.find('body').send_keys :escape
    assert_content('You are about to cancel the import process. Are you sure you want to do this?')
    click_on 'Proceed to Cancel'
    sleep(0.75) # wait for import modal to close
    assert page.has_no_content?("Import #{file_type}")
    click_on 'Import'
    find('a', text: file_type).click
    page.attach_file(file_fixture(file_name))
    click_on 'Upload'
    sleep(0.75) # wait for import modal to open
    find('.modal-body').find('div.card-body', match: :first).find('button', text: 'Accept').click
    sleep(0.75) # wait for patient to be accepted
    find('button.close').click
    assert_content('You are about to stop the import process. Are you sure you want to do this?')
    click_on 'Return to Import'
    sleep(0.75) # wait for cancel import modal to close
    page.find('body').send_keys :escape
    assert_content('You are about to stop the import process. Are you sure you want to do this?')
    click_on 'Proceed to Stop'
    sleep(0.75) # wait for import modal to close
    assert page.has_no_content?("Import #{file_type}")
  end

  def download_sara_alert_format_guidance(workflow)
    find("##{workflow}-nav-btn").click if workflow.present?
    click_on 'Import'
    find('a', text: "Sara Alert Format (#{workflow})").click
    click_on 'Download formatting guidance'
    @@public_health_export_verifier.verify_sara_alert_format_guidance
    @@system_test_utils.wait_for_modal_animation
    click_on(class: 'close')
    @@system_test_utils.wait_for_modal_animation
  end

  def select_monitorees_for_bulk_edit(workflow, tab, patient_labels)
    find("##{workflow}-nav-btn").click if workflow.present?
    sleep(2)
    @@system_test_utils.go_to_tab(tab)
    sleep(2)
    patient_labels.each { |patient_label| find_by_id("patients-#{PATIENTS[patient_label]['id']}").find('input').click }
  end

  def bulk_edit_update_case_status(workflow, case_status, next_step, apply_to_household)
    click_on 'Actions'
    click_on 'Update Case Status'
    select(case_status, from: 'case_status')
    select(next_step, from: 'follow_up') if workflow != :isolation && %w[Confirmed Probable].include?(case_status)
    find_by_id('apply_to_household', { visible: :all }).check({ allow_label_click: true }) if apply_to_household
    click_on 'Submit'
    find("##{workflow == :isolation ? :exposure : :isolation}-nav-btn").click if next_step != 'End Monitoring' # go to other workflow
  end

  def bulk_edit_close_records(monitoring_reason, reasoning, apply_to_household)
    click_on 'Actions'
    click_on 'Close Records'
    select(monitoring_reason, from: 'monitoring_reason') if monitoring_reason.present?
    fill_in 'reasoning', with: reasoning
    find_by_id('apply_to_household', { visible: :all }).check({ allow_label_click: true }) if apply_to_household
    click_on 'Submit'
  end

  def bulk_edit_update_assigned_user(assigned_user, apply_to_household)
    click_on 'Actions'
    click_on 'Update Assigned User'
    fill_in 'assigned_user_input', with: assigned_user
    find_by_id('apply_to_household', { visible: :all }).check({ allow_label_click: true }) if apply_to_household
    click_on 'Submit'
  end
end
