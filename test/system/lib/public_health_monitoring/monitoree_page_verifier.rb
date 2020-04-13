# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'reports_verifier'
require_relative '../system_test_utils'

class PublicHealthMonitoringMonitoreePageVerifier < ApplicationSystemTestCase
  @@public_health_monitoring_reports_verifier = PublicHealthMonitoringReportsVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_patient_details_and_reports(patient, workflow)
    fill_in 'Search:', with: patient.last_name
    click_on "#{patient.last_name}, #{patient.first_name}"
    verify_patient_details(patient)
    @@public_health_monitoring_reports_verifier.verify_workflow(workflow)
    @@public_health_monitoring_reports_verifier.verify_existing_reports(patient)
    @@public_health_monitoring_reports_verifier.verify_pause_notifications(patient.pause_notifications)
    @@system_test_utils.return_to_dashboard(workflow)
  end

  def verify_patient_details(patient)
    find('#patient-info-header').click
    fields = ['first_name', 'last_name']
    fields.each { |field|
      assert page.has_content?(patient[field]), @@system_test_utils.get_err_msg('Monitoree details', field, patient[field])
    }
  end
end
