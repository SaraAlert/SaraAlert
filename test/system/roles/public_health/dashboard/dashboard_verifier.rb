# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard'
require_relative '../../../lib/system_test_utils'

class PublicHealthDashboardVerifier < ApplicationSystemTestCase
  @@public_health_dashboard = PublicHealthDashboard.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_patients_on_dashboard(jurisdiction_id, verify_scope: false)
    jurisdiction = Jurisdiction.find(jurisdiction_id)
    patients = jurisdiction.all_patients_excluding_purged
    sleep(0.5) # wait for page count to load
    verify_workflow_count(:exposure, patients.where(isolation: false).count)
    verify_workflow_count(:isolation, patients.where(isolation: true).count)
    verify_patients_under_tab(jurisdiction, verify_scope, :exposure, :symptomatic, patients.exposure_symptomatic)
    verify_patients_under_tab(jurisdiction, verify_scope, :exposure, :non_reporting, patients.exposure_non_reporting)
    verify_patients_under_tab(jurisdiction, verify_scope, :exposure, :asymptomatic, patients.exposure_asymptomatic)
    verify_patients_under_tab(jurisdiction, verify_scope, :exposure, :pui, patients.exposure_under_investigation)
    verify_patients_under_tab(jurisdiction, verify_scope, :exposure, :closed, patients.monitoring_closed_without_purged.where(isolation: false))
    verify_patients_under_tab(jurisdiction, false, :exposure, :transferred_in, jurisdiction.transferred_in_patients.where(isolation: false))
    verify_patients_under_tab(jurisdiction, false, :exposure, :transferred_out, jurisdiction.transferred_out_patients.where(isolation: false))
    verify_patients_under_tab(jurisdiction, verify_scope, :exposure, :all, patients.where(isolation: false))
    @@system_test_utils.go_to_workflow('isolation')
    sleep(0.5) # wait for page count to load
    verify_workflow_count(:exposure, patients.where(isolation: false).count)
    verify_workflow_count(:isolation, patients.where(isolation: true).count)
    verify_patients_under_tab(jurisdiction, verify_scope, :isolation, :requiring_review, patients.isolation_requiring_review)
    verify_patients_under_tab(jurisdiction, verify_scope, :isolation, :non_reporting, patients.isolation_non_reporting)
    verify_patients_under_tab(jurisdiction, verify_scope, :isolation, :reporting, patients.isolation_reporting)
    verify_patients_under_tab(jurisdiction, false, :isolation, :transferred_in, jurisdiction.transferred_in_patients.where(isolation: true))
    verify_patients_under_tab(jurisdiction, false, :isolation, :transferred_out, jurisdiction.transferred_out_patients.where(isolation: true))
    verify_patients_under_tab(jurisdiction, verify_scope, :isolation, :all, patients.where(isolation: true))
  end

  def verify_workflow_count(workflow, expected_count)
    displayed_count = find_by_id("#{workflow}Count").text.tr('()', '').to_i
    assert_equal(expected_count, displayed_count, @@system_test_utils.get_err_msg('dashboard', "#{workflow} monitoring type count", expected_count))
  end

  def verify_patients_under_tab(jurisdiction, verify_scope, workflow, tab, patients)
    @@system_test_utils.go_to_tab(tab)
    assert_equal(patients.count, patient_count_under_tab(tab), @@system_test_utils.get_err_msg('dashboard', "#{tab} tab count", patients.count))
    patients.each do |patient|
      verify_patient_under_tab(jurisdiction, verify_scope, workflow, tab, patient)
    end
  end

  def verify_patient_under_tab(jurisdiction, verify_scope, workflow, tab, patient)
    # view patient without any filters
    fill_in 'search', with: patient.last_name if patient_count_under_tab(tab) > find_field('entries')['value'].to_i
    verify_patient_info(patient, workflow, tab)

    return if %i[transferred_in transferred_out].include?(tab)

    # view patient with assigned jurisdiction filter
    Jurisdiction.find(jurisdiction.subtree_ids).each do |jur|
      fill_in 'jurisdiction_path', with: jur[:path]
      verify_patient_info(patient, workflow, tab) if patient.jurisdiction[:path].include?(jur[:name])

      find_by_id('exactJurisdiction').click
      sleep(1.5) # wait for data to load
      if verify_scope && tab == :all
        page.all('tbody tr').each do |row|
          assigned_jurisdiction_cell = row.all('td')[1]
          assert_equal(jur[:name], assigned_jurisdiction_cell.text) unless assigned_jurisdiction_cell.nil?
        end
      end
      verify_patient_info(patient, workflow, tab) if patient.jurisdiction[:path] == jur[:path]
      find_by_id('allJurisdictions').click
    end
    fill_in 'jurisdiction_path', with: jurisdiction[:path]

    # view patient with assigned user filter
    if patient[:assigned_user].nil?
      find_by_id('noAssignedUser').click
    else
      fill_in 'assigned_user', with: patient[:assigned_user]
    end
    verify_patient_info(patient, workflow, tab)
    find_by_id('allAssignedUsers').click
  end

  def patient_count_under_tab(tab)
    find("##{tab}_tab").first(:xpath, './/span').text.to_i
  end

  def verify_patient_info(patient, workflow, tab)
    verify_patient_field('name', patient.displayed_name)
    verify_patient_field('assigned jurisdiction', patient.jurisdiction[:name]) unless %i[transferred_in transferred_out].include?(tab)
    verify_patient_field('from jurisdiction', Jurisdiction.find(patient[:transferred_from]))[:path] if tab == :transferred_in && patient[:transferred_from]
    verify_patient_field('to jurisdiction', patient.jurisdiction[:path]) if tab == :transferred_out
    verify_patient_field('assigned user', patient[:assigned_user]) unless %i[transferred_in transferred_out].include?(tab)
    verify_patient_field('state/local id', patient[:user_defined_id_statelocal])
    verify_patient_field('date of birth', patient[:date_of_birth].strftime('%m/%d/%Y'))
    verify_patient_field('end of monitoring', Date.parse(patient.end_of_monitoring).strftime('%m/%d/%Y')) unless workflow == :isolation || tab == :closed
    verify_patient_field('risk level', patient[:exposure_risk_assessment]) unless workflow == :isolation || tab == :closed
    verify_patient_field('monitoring plan', patient[:monitoring_plan]) unless %i[closed pui].include?(tab)
    verify_patient_field('public health action', patient[:public_health_action]) if tab == :pui
    # verify_patient_field('expected purge date', patient.expected_purge_date) if tab == :closed # local timezone
    verify_patient_field('reason for closure', patient[:monitoring_reason]) if tab == :closed
    # verify_patient_field('closed at', patient[:closed_at]) if tab == :closed # local timezone
    # verify_patient_field('transferred at', patient[:latest_transfer_at]) if %i[transferred_in transferred_out].include?(tab) # local timezone
    # verify_patient_field('latest report', patient[:latest_assessment_at]) unless %i[transferred_in transferred_out].include?(tab) # local timezone
    verify_patient_field('status', patient.status.to_s.gsub('_', ' ').gsub('exposure ', '')&.gsub('isolation ', '')) if tab == :all
  end

  def verify_patient_field(field, value)
    assert page.find('tbody').has_content?(value), @@system_test_utils.get_err_msg('Patient info', field, value) unless value.nil?
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

  def search_for_and_verify_patient_monitoring_actions(patient_label, assertions, apply_to_household)
    return if patient_label.nil?

    @@public_health_dashboard.search_for_and_view_patient('all', patient_label)
    patient = Patient.find(@@system_test_utils.patients[patient_label]['id'])
    assertions.each do |field, value|
      assert_equal value, patient[field], @@system_test_utils.get_err_msg('Bulk edit', field, value)
    end
    monitoring_status = patient.monitoring ? 'Actively Monitoring' : 'Not Monitoring'
    public_health_action = patient.public_health_action == '' ? 'None' : patient.public_health_action
    assert page.has_select?('monitoring_status', selected: monitoring_status)
    assert page.has_select?('exposure_risk_assessment', selected: patient.exposure_risk_assessment.to_s)
    assert page.has_select?('monitoring_plan', selected: patient.monitoring_plan.to_s)
    assert page.has_select?('case_status', selected: patient.case_status.to_s)
    assert page.has_select?('public_health_action', selected: public_health_action)
    assert page.has_field?('assigned_user', with: patient.assigned_user.to_s)
    assert page.has_field?('jurisdiction_id', with: patient.jurisdiction.jurisdiction_path_string)
    @@system_test_utils.return_to_dashboard(nil)
    return unless apply_to_household

    patient.dependents.each do |dependent|
      label = "patient_#{dependent.id}"
      search_for_and_verify_patient_monitoring_actions(label, assertions, false)
    end
  end
end
