# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard'
require_relative '../system_test_utils'

class PublicHealthMonitoringDashboardVerifier < ApplicationSystemTestCase
  @@public_health_monitoring_dashboard = PublicHealthMonitoringDashboard.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  PATIENTS = @@system_test_utils.get_patients
  
  def verify_patients_on_dashboard(jurisdiction_id)
    jurisdiction = Jurisdiction.find(jurisdiction_id)
    monitorees = jurisdiction.all_patients
    verify_workflow_count('Exposure Monitoring', monitorees.where(isolation: false).count)
    verify_workflow_count('Isolation Monitoring', monitorees.where(isolation: true).count)
    verify_patients_under_tab('symptomatic', monitorees.symptomatic.where(isolation: false))
    verify_patients_under_tab('non-reporting', monitorees.non_reporting.where(isolation: false))
    verify_patients_under_tab('asymptomatic', monitorees.asymptomatic.where(isolation: false))
    verify_patients_under_tab('pui', monitorees.under_investigation.where(isolation: false))
    verify_patients_under_tab('closed', monitorees.monitoring_closed_without_purged.where(isolation: false))
    verify_patients_under_tab('transferred-in', jurisdiction.transferred_in_patients.where(isolation: false))
    verify_patients_under_tab('transferred-out', jurisdiction.transferred_out_patients.where(isolation: false))
    verify_patients_under_tab('all', monitorees.where(isolation: false))
    @@system_test_utils.go_to_workflow('isolation')
    verify_patients_under_tab('requiring-review', monitorees.isolation_requiring_review.where(isolation: true))
    verify_patients_under_tab('non-reporting', monitorees.isolation_non_reporting.where(isolation: true))
    verify_patients_under_tab('reporting', monitorees.isolation_reporting.where(isolation: true))
    verify_patients_under_tab('transferred-in', jurisdiction.transferred_in_patients.where(isolation: true))
    verify_patients_under_tab('transferred-out', jurisdiction.transferred_out_patients.where(isolation: true))
    verify_patients_under_tab('all', monitorees.where(isolation: true))
  end

  def verify_workflow_count(workflow, expected_count)
    displayed_count = find('a', text: workflow).text.tr("#{workflow} ()", '').to_i
    assert_equal(expected_count, displayed_count, @@system_test_utils.get_err_msg('dashboard', "#{workflow} monitoring type count", expected_count))
  end
  
  def verify_patients_under_tab(tab, patients)
    @@system_test_utils.go_to_tab(tab)
    assert_equal(patients.count, patient_count_under_tab(tab), @@system_test_utils.get_err_msg('dashboard', "#{tab} tab count", patients.count))
    patients.each do |patient|
      verify_patient_under_tab(tab, patient)
    end
  end
  
  def verify_patient_under_tab(tab, patient)
    if patient_count_under_tab(tab) > find('select', class: 'custom-select')['value'].to_i
      fill_in 'Search:', with: patient.last_name
    end
    assert page.has_content?(patient.first_name), @@system_test_utils.get_err_msg('Patient info', 'first name', patient.first_name)
    assert page.has_content?(patient.last_name), @@system_test_utils.get_err_msg('Patient info', 'last name', patient.last_name)
  end

  def patient_count_under_tab(tab)
    displayed_count = find("##{tab}-tab").first(:xpath, './/span').text.to_i
  end

  def verify_monitoree_under_tab(tab, monitoree_key)
    @@system_test_utils.go_to_tab(tab)
    search_for_and_verify_monitoree(monitoree_key, true, tab == 'Transferred Out' ? 'td' : 'a')
  end

  def search_for_and_verify_monitoree(monitoree_key, should_exist, selector='a')
    @@public_health_monitoring_dashboard.search_for_monitoree(monitoree_key)
    monitoree_display_name = @@system_test_utils.get_monitoree_display_name(monitoree_key)
    if should_exist
      assert page.has_content?(monitoree_display_name), @@system_test_utils.get_err_msg('Dashboard', 'monitoree name', monitoree_display_name)
    else
      assert page.has_no_content?(monitoree_display_name), @@system_test_utils.get_err_msg('Dashboard', 'monitoree name', monitoree_display_name)
    end
  end
end
