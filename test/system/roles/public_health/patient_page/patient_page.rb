# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'patient_page_verifier'
require_relative '../../../lib/system_test_utils'

class PublicHealthPatientPage < ApplicationSystemTestCase
  @@public_health_patient_page_verifier = PublicHealthPatientPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  USERS = @@system_test_utils.users
  PATIENTS = @@system_test_utils.patients

  def view_patients_details_and_reports(jurisdiction_id)
    monitorees = Jurisdiction.find(jurisdiction_id).all_patients_excluding_purged
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

  def move_to_household(user_label, patient_label, target_hoh_label)
    search_in_move_to_household_modal(user_label, patient_label, target_hoh_label)
    select_in_move_to_household_modal(user_label, patient_label, target_hoh_label)
    # TODO: Pagination and sorting tests.
  end

  def search_in_move_to_household_modal(_user_label, _patient_label, target_hoh_label)
    first_name = PATIENTS[target_hoh_label]['first_name']
    last_name = PATIENTS[target_hoh_label]['last_name']
    user_defined_id_statelocal = PATIENTS[target_hoh_label]['user_defined_id_statelocal']
    displayed_name = "#{last_name}, #{first_name}"

    click_on 'Move To Household'

    # Searching by last name
    fill_in 'search', with: last_name
    assert page.find('tbody').has_link?(displayed_name)
    assert page.find('tbody').has_button?('Select', count: 1)

    # Searching by last name
    fill_in 'search', with: first_name
    assert page.find('tbody').has_link?(displayed_name)
    assert page.find('tbody').has_button?('Select', count: 1)

    # Searching by State/Local ID
    fill_in 'search', with: user_defined_id_statelocal
    assert page.find('tbody').has_text?(user_defined_id_statelocal.to_s)
    assert page.find('tbody').has_button?('Select', count: 1)

    click_on 'Cancel'
  end

  def select_in_move_to_household_modal(_user_label, _patient_label, target_hoh_label)
    new_responder_id = PATIENTS[target_hoh_label]['id']

    click_on 'Move To Household'
    fill_in 'search', with: PATIENTS[target_hoh_label]['last_name']
    assert page.has_button?('Select', count: 1)
    click_on 'Select'

    assert page.has_link?('Click here to view that monitoree', href: "/patients/#{new_responder_id}")
  end
end
