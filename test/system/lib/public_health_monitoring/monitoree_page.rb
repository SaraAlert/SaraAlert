# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'monitoree_page_verifier'
require_relative '../system_test_utils'

class PublicHealthMonitoringMonitoreePage < ApplicationSystemTestCase
  @@public_health_monitoring_monitoree_page_verifier = PublicHealthMonitoringMonitoreePageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def view_patients_details_and_reports(jurisdiction_id)
    monitorees = Jurisdiction.find(jurisdiction_id).all_patients
    click_on 'All Monitorees'
    monitorees.where(isolation: false).where(monitoring: true).each { |patient|
      @@public_health_monitoring_monitoree_page_verifier.verify_patient_details_and_reports(patient, 'exposure')
    }
    @@system_test_utils.go_to_workflow('isolation')
    click_on 'All Cases'
    monitorees.where(isolation: true).where(monitoring: true).each { |patient|
      @@public_health_monitoring_monitoree_page_verifier.verify_patient_details_and_reports(patient, 'isolation')
    }
  end
end
