# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'patient_page_verifier'
require_relative '../../../lib/system_test_utils'

class PublicHealthPatientPage < ApplicationSystemTestCase
  @@public_health_patient_page_verifier = PublicHealthPatientPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def view_patients_details_and_reports(jurisdiction_id)
    monitorees = Jurisdiction.find(jurisdiction_id).all_patients
    click_on 'All Monitorees'
    monitorees.where(isolation: false).where(monitoring: true).each do |patient|
      @@public_health_patient_page_verifier.verify_patient_details_and_reports(patient, 'exposure')
    end
    @@system_test_utils.go_to_workflow('isolation')
    click_on 'All Cases'
    monitorees.where(isolation: true).where(monitoring: true).each do |patient|
      @@public_health_patient_page_verifier.verify_patient_details_and_reports(patient, 'isolation')
    end
  end
end
