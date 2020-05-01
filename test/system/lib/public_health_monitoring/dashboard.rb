# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'reports'
require_relative '../system_test_utils'

class PublicHealthMonitoringDashboard < ApplicationSystemTestCase
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

  def export_line_list_csv
    click_on 'Export'
    click_on 'Line list CSV'
  end

  def export_sara_alert_format_csv
    click_on 'Export'
    click_on 'Sara Alert Format CSV'
  end

  def export_excel_purge_eligible_monitorees(download=true)
    click_on 'Export'
    click_on 'Excel Export For Purge-Eligible Monitorees'
    if download
      click_on 'Download'
    else
      click_on 'Cancel'
    end
  end

  def export_excel_all_monitorees(download=true)
    click_on 'Export'
    click_on 'Excel Export For All Monitorees'
    if download
      click_on 'Download'
    else
      click_on 'Cancel'
    end
  end

  def import_epi_x
    click_on 'Import'
    find('a', text: 'Epi-X').click
  end

  def import_sara_alert_format
    click_on 'Import'
    find('a', text: 'Sara Alert Format').click
  end
end
