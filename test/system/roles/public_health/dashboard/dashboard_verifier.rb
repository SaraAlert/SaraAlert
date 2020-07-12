# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard'
require_relative '../../../lib/system_test_utils'

class PublicHealthDashboardVerifier < ApplicationSystemTestCase
  @@public_health_dashboard = PublicHealthDashboard.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_patients_on_dashboard(jurisdiction_id, verify_scope = false)
    jurisdiction = Jurisdiction.find(jurisdiction_id)
    patients = jurisdiction.all_patients
    verify_workflow_count('exposure', patients.where(isolation: false).count)
    verify_workflow_count('isolation', patients.where(isolation: true).count)
    verify_patients_under_tab(jurisdiction, verify_scope, 'symptomatic', patients.exposure_symptomatic)
    verify_patients_under_tab(jurisdiction, verify_scope, 'non_reporting', patients.exposure_non_reporting)
    verify_patients_under_tab(jurisdiction, verify_scope, 'asymptomatic', patients.exposure_asymptomatic)
    verify_patients_under_tab(jurisdiction, verify_scope, 'pui', patients.exposure_under_investigation)
    verify_patients_under_tab(jurisdiction, verify_scope, 'closed', patients.monitoring_closed_without_purged.where(isolation: false))
    verify_patients_under_tab(jurisdiction, false, 'transferred_in', jurisdiction.transferred_in_patients.where(isolation: false))
    verify_patients_under_tab(jurisdiction, false, 'transferred_out', jurisdiction.transferred_out_patients.where(isolation: false))
    verify_patients_under_tab(jurisdiction, verify_scope, 'all', patients.where(isolation: false))
    @@system_test_utils.go_to_workflow('isolation')
    @@system_test_utils.wait_for_page_count_load_delay
    verify_workflow_count('exposure', patients.where(isolation: false).count)
    verify_workflow_count('isolation', patients.where(isolation: true).count)
    verify_patients_under_tab(jurisdiction, verify_scope, 'requiring_review', patients.isolation_requiring_review)
    verify_patients_under_tab(jurisdiction, verify_scope, 'non_reporting', patients.isolation_non_reporting)
    verify_patients_under_tab(jurisdiction, verify_scope, 'reporting', patients.isolation_reporting)
    verify_patients_under_tab(jurisdiction, false, 'transferred_in', jurisdiction.transferred_in_patients.where(isolation: true))
    verify_patients_under_tab(jurisdiction, false, 'transferred_out', jurisdiction.transferred_out_patients.where(isolation: true))
    verify_patients_under_tab(jurisdiction, verify_scope, 'all', patients.where(isolation: true))
  end

  def verify_workflow_count(workflow, expected_count)
    displayed_count = find_by_id("#{workflow}Count").text.tr('()', '').to_i
    assert_equal(expected_count, displayed_count, @@system_test_utils.get_err_msg('dashboard', "#{workflow} monitoring type count", expected_count))
  end

  def verify_patients_under_tab(jurisdiction, verify_scope, tab, patients)
    @@system_test_utils.go_to_tab(tab)
    assert_equal(patients.count, patient_count_under_tab(tab), @@system_test_utils.get_err_msg('dashboard', "#{tab} tab count", patients.count))
    patients.each do |patient|
      verify_patient_under_tab(jurisdiction, verify_scope, tab, patient)
    end
  end

  def verify_patient_under_tab(jurisdiction, verify_scope, tab, patient)
    # view patient without any filters
    fill_in 'search', with: patient.last_name if patient_count_under_tab(tab) > find_field('entries')['value'].to_i
    verify_patient_info_in_data_table(patient, tab)

    return if %w[transferred_in transferred_out].include?(tab)

    # view patient with assigned jurisdiction filter
    Jurisdiction.find(jurisdiction.subtree_ids).each do |jur|
      fill_in 'jurisdictionPath', with: jur[:path]
      verify_patient_info_in_data_table(patient, tab) if patient.jurisdiction[:path].include?(jur[:name])

      find_by_id('exactJurisdiction').click
      if verify_scope
        page.all('.dataTable tbody tr').each do |row|
          assigned_jurisdiction_cell = row.all('td')[tab == 'transferred_out' ? 1 : 2]
          assert_equal(jur[:name], assigned_jurisdiction_cell.text) unless assigned_jurisdiction_cell.nil?
        end
      end
      verify_patient_info_in_data_table(patient, tab) if patient.jurisdiction[:path] == jur[:path]
      find_by_id('allJurisdictions').click
    end
    fill_in 'jurisdictionPath', with: jurisdiction[:path]

    # view patient with assigned user filter
    if patient[:assigned_user].nil?
      find_by_id('noAssignedUser').click
    else
      fill_in 'assignedUser', with: patient[:assigned_user]
    end
    verify_patient_info_in_data_table(patient, tab)
    find_by_id('allAssignedUsers').click
  end

  def patient_count_under_tab(tab)
    find("##{tab}_tab").first(:xpath, './/span').text.to_i
  end

  def verify_patient_info_in_data_table(patient, tab)
    verify_patient_field_in_data_table('first name', patient.first_name)
    verify_patient_field_in_data_table('last name', patient.last_name)
    verify_patient_field_in_data_table('state/local id', patient.user_defined_id_statelocal)
    verify_patient_field_in_data_table('sex', patient.sex)
    verify_patient_field_in_data_table('date of birth', patient.date_of_birth)
    verify_patient_field_in_data_table('monitoring plan', patient.monitoring_plan)
    if tab == 'transferred_in'
      from_jurisdiction = Transfer.where(patient_id: patient.id, to_jurisdiction: patient.jurisdiction.id).order(created_at: :desc).first.from_jurisdiction
      verify_patient_field_in_data_table('from jurisdiction', from_jurisdiction[:path])
    elsif tab == 'transferred_out'
      verify_patient_field_in_data_table('to jurisdiction', patient.jurisdiction[:path])
    else
      verify_patient_field_in_data_table('assigned jurisdiction', patient.jurisdiction[:name])
      verify_patient_field_in_data_table('assigned user', patient.assigned_user)
    end
  end

  def verify_patient_field_in_data_table(field, value)
    assert page.has_content?(value), @@system_test_utils.get_err_msg('Patient info', field, value) unless value.nil?
  end

  def verify_monitoree_under_tab(tab, monitoree_label)
    @@system_test_utils.go_to_tab(tab)
    search_for_and_verify_monitoree(monitoree_label, true)
  end

  def search_for_and_verify_monitoree(monitoree_label, should_exist)
    @@public_health_dashboard.search_for_monitoree(monitoree_label)
    monitoree_display_name = @@system_test_utils.get_monitoree_display_name(monitoree_label)
    if should_exist
      assert page.has_content?(monitoree_display_name), @@system_test_utils.get_err_msg('Dashboard', 'monitoree name', monitoree_display_name)
    else
      assert page.has_no_content?(monitoree_display_name), @@system_test_utils.get_err_msg('Dashboard', 'monitoree name', monitoree_display_name)
    end
  end

  def search_for_and_verify_patient_monitoring_actions(patient_label, apply_to_group)
    return if patient_label.nil?

    @@public_health_dashboard.search_for_and_view_patient('all', patient_label)
    monitoree = Patient.find(@@system_test_utils.patients[patient_label]['id'])
    monitoring_status = monitoree.monitoring ? 'Actively Monitoring' : 'Not Monitoring'
    public_health_action = monitoree.public_health_action == '' ? 'None' : monitoree.public_health_action
    assert page.has_select?('monitoring_status', selected: monitoring_status)
    assert page.has_select?('exposure_risk_assessment', selected: monitoree.exposure_risk_assessment.to_s)
    assert page.has_select?('monitoring_plan', selected: monitoree.monitoring_plan.to_s)
    assert page.has_select?('case_status', selected: monitoree.case_status.to_s)
    assert page.has_select?('public_health_action', selected: public_health_action)
    assert page.has_field?('assignedUser', with: monitoree.assigned_user.to_s)
    assert page.has_field?('jurisdictionId', with: monitoree.jurisdiction.jurisdiction_path_string)
    @@system_test_utils.return_to_dashboard(nil)
    return unless apply_to_group

    monitoree.dependents.each do |dependent|
      label = "patient_#{dependent.id}"
      search_for_and_verify_patient_monitoring_actions(label, false)
    end
  end
end
