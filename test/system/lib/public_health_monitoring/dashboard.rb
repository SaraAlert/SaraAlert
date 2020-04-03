# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'reports'
require_relative '../system_test_utils'

class PublicHealthMonitoringDashboard < ApplicationSystemTestCase
  @@public_health_monitoring_reports = PublicHealthMonitoringReports.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)
  
  PATIENTS = @@system_test_utils.get_patients
  MONITOREES = @@system_test_utils.get_monitorees
  
  def search_for_and_view_patient(tab, patient_key)
    @@system_test_utils.go_to_tab(tab)
    fill_in 'Search:', with: PATIENTS[patient_key]['last_name']
    click_on @@system_test_utils.get_patient_display_name(patient_key)
  end

  def search_for_and_view_monitoree(tab, monitoree_key)
    @@system_test_utils.go_to_tab(tab)
    fill_in 'Search:', with: MONITOREES[monitoree_key]['identification']['last_name']
    click_on @@system_test_utils.get_monitoree_display_name(monitoree_key)
  end

  def search_for_monitoree(monitoree_key)
    fill_in 'Search:', with: MONITOREES[monitoree_key]['identification']['last_name']
  end

  def export_linelist_data_to_csv
    click_on 'Export'
    click_on 'Line list CSV'
  end

  def export_comprehensive_data_to_csv
    click_on 'Export'
    click_on 'Sara Alert Format CSV'
  end

  def import_epi_x_data
    click_on 'Import'
    find('a', text: 'Epi-X').click
  end

  def import_sara_alert_format_data
    click_on 'Import'
    find('a', text: 'Sara Alert Format').click
  end
end
