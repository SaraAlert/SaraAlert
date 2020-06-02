# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'export_verifier'
require_relative 'import_verifier'
require_relative 'reports'
require_relative '../system_test_utils'

class PublicHealthMonitoringDashboard < ApplicationSystemTestCase
  @@public_health_export_verifier = PublicHealthMonitoringExportVerifier.new(nil)
  @@public_health_import_verifier = PublicHealthMonitoringImportVerifier.new(nil)
  @@public_health_monitoring_reports = PublicHealthMonitoringReports.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  PATIENTS = @@system_test_utils.get_patients
  MONITOREES = @@system_test_utils.get_monitorees

  def search_for_and_view_patient(tab, patient_label)
    @@system_test_utils.go_to_tab(tab)
    fill_in 'Search:', with: PATIENTS[patient_label]['last_name']
    click_on @@system_test_utils.get_patient_display_name(patient_label)
  end

  def search_for_and_view_monitoree(tab, monitoree_label)
    @@system_test_utils.go_to_tab(tab)
    fill_in 'Search:', with: MONITOREES[monitoree_label]['identification']['last_name']
    click_on @@system_test_utils.get_monitoree_display_name(monitoree_label)
  end

  def search_for_monitoree(monitoree_label)
    fill_in 'Search:', with: MONITOREES[monitoree_label]['identification']['last_name']
  end

  def export_line_list_csv(jurisdiction_id, workflow)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Export'
    click_on 'Line list CSV'
    @@public_health_export_verifier.verify_line_list_csv(jurisdiction_id, workflow)
  end

  def export_sara_alert_format(jurisdiction_id, workflow)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Export'
    click_on 'Sara Alert Format'
    @@public_health_export_verifier.verify_sara_alert_format(jurisdiction_id, workflow)
  end

  def export_excel_purge_eligible_monitorees(jurisdiction_id, action)
    click_on 'Export'
    click_on 'Excel Export For Purge-Eligible Monitorees'
    if action == :download
      click_on 'Download'
      @@public_health_export_verifier.verify_excel_purge_eligible_monitorees(jurisdiction_id)
    else
      click_on 'Cancel'
    end
  end

  def export_excel_all_monitorees(jurisdiction_id, action)
    click_on 'Export'
    click_on 'Excel Export For All Monitorees'
    if action == :download
      click_on 'Download'
      @@public_health_export_verifier.verify_excel_all_monitorees(jurisdiction_id)
    else
      click_on 'Cancel'
    end
  end

  def export_excel_single_monitoree(patient_label)
    search_for_and_view_patient('all', patient_label)
    click_on 'Download Excel Export'
    @@public_health_export_verifier.verify_excel_single_monitoree(patient_label.split('_')[1].to_i)
  end

  def import_epi_x(jurisdiction_id, workflow, file_name, validity, rejects, accept_duplicates)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Import'
    find('a', text: 'Epi-X').click
    attach_file('file', file_fixture(file_name))
    click_on 'Upload'
    if validity == :valid
      @@public_health_import_verifier.verify_epi_x_import_page(jurisdiction_id, file_name)
      select_monitorees_to_import(rejects, accept_duplicates)
      @@public_health_import_verifier.verify_epi_x_import_data(jurisdiction_id, workflow, file_name, rejects, accept_duplicates)
    elsif validity == :invalid_file
      assert_content('Please make sure that your import file is a .xlsx file.')
    elsif validity == :invalid_format
      assert_content('Please make sure that .xlsx import file is formatted in accordance with the formatting guidance.')
    elsif validity == :invalid_headers
      assert_content('Invalid headers, please make sure to use the latest Epi-X format.')
    elsif validity == :invalid_monitorees
      assert_content('File must contain at least one monitoree to import')
    elsif validity == :invalid_fields
      @@public_health_import_verifier.verify_epi_x_field_validation(workflow, file_name)
    end
  end

  def import_sara_alert_format(jurisdiction_id, workflow, file_name, validity, rejects, accept_duplicates)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Import'
    find('a', text: 'Sara Alert Format').click
    attach_file('file', file_fixture(file_name))
    click_on 'Upload'
    if validity == :valid
      @@public_health_import_verifier.verify_sara_alert_format_import_page(jurisdiction_id, file_name)
      select_monitorees_to_import(rejects, accept_duplicates)
      @@public_health_import_verifier.verify_sara_alert_format_import_data(jurisdiction_id, workflow, file_name, rejects, accept_duplicates)
    elsif validity == :invalid_file
      assert_content('Please make sure that your import file is a .xlsx file.')
    elsif validity == :invalid_format
      assert_content('Please make sure that .xlsx import file is formatted in accordance with the formatting guidance.')
    elsif validity == :invalid_headers
      assert_content('Invalid headers, please make sure to use the latest format specified by the Sara Alert Format guidance doc.')
    elsif validity == :invalid_monitorees
      assert_content('File must contain at least one monitoree to import')
    elsif validity == :invalid_fields
      @@public_health_import_verifier.verify_sara_alert_format_field_validation(workflow, file_name)
    elsif validity == :invalid_jurisdiction
      assert_content(' is not a valid jurisdiction for field \'Jurisdiction Path\'')
    end
  end

  def download_sara_alert_format_guidance(workflow)
    click_on 'Isolation Monitoring' if workflow == :isolation
    click_on 'Import'
    find('a', text: 'Sara Alert Format').click
    click_on 'Download formatting guidance'
    @@public_health_export_verifier.verify_sara_alert_format_guidance
    @@system_test_utils.wait_for_modal_animation
    click_on(class: 'close')
    @@system_test_utils.wait_for_modal_animation
  end

  def select_monitorees_to_import(rejects, accept_duplicates)
    if rejects.nil?
      click_on 'Import All'
      find(:css, '.form-check-input').set(true) if accept_duplicates
      click_on 'OK'
    else
      page.all('div.card-body').each_with_index do |card, index|
        if rejects.include?(index)
          card.find('button', text: 'Reject').click
        else
          card.find('button', text: 'Accept').click
        end
        @@system_test_utils.wait_for_accept_reject
      end
    end
  end
end
