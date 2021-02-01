# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../enrollment/steps'
require_relative '../../../lib/system_test_utils'

class EnrollerPatientPageVerifier < ApplicationSystemTestCase
  include ImportExport
  @@enrollment_form_steps = EnrollmentFormSteps.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  PATIENTS = @@system_test_utils.patients

  def verify_monitoree_info(monitoree, is_epi: false)
    find('#details-expander-link').click if is_epi
    @@enrollment_form_steps.steps.each do |enrollment_step, enrollment_fields|
      verify_enrollment_step(monitoree[enrollment_step.to_s], enrollment_fields)
    end
  end

  def verify_group_member_info(existing_monitoree, new_monitoree, is_epi: false)
    find('#details-expander-link').click if is_epi
    verify_enrollment_step(new_monitoree['identification'], @@enrollment_form_steps.steps[:identification])
    verify_enrollment_step(existing_monitoree['address'], @@enrollment_form_steps.steps[:address])
    verify_enrollment_step(existing_monitoree['contact_information'], @@enrollment_form_steps.steps[:contact_information])
    verify_enrollment_step(existing_monitoree['arrival_information'], @@enrollment_form_steps.steps[:arrival_information])
    verify_enrollment_step(existing_monitoree['planned_travel'], @@enrollment_form_steps.steps[:planned_travel])
    verify_enrollment_step(existing_monitoree['potential_exposure_information'], @@enrollment_form_steps.steps[:potential_exposure_information])
  end

  def verify_enrollment_step(data, fields)
    return unless data

    fields.each do |field|
      if data[field[:id]] && field[:info_page]
        if %w[text select date].include?(field[:type])
          assert page.has_content?(data[field[:id]]), @@system_test_utils.get_err_msg('Monitoree details', field[:id], data[field[:id]])
        elsif field[:type] == 'phone'
          phone = format_phone_number(data[field[:id]])
          assert page.has_content?(phone), @@system_test_utils.get_err_msg('Monitoree details', field[:id], phone)
        elsif field[:type] == 'age'
          age = @@system_test_utils.calculate_age(data[field[:id]])
          assert page.has_content?(age), @@system_test_utils.get_err_msg('Monitoree details', field[:id], age)
        elsif field[:type] == 'race'
          assert page.has_content?(field[:info_page]), @@system_test_utils.get_err_msg('Monitoree details', field[:info_page], 'present')
        elsif field[:type] == 'checkbox' || field[:type] == 'risk_factor'
          assert page.has_content?(field[:label]), @@system_test_utils.get_err_msg('Monitoree details', field[:label], 'present')
        end
      end
    end
  end

  # Verifies that only components the user has access to are rendered.
  def verify_monitoree_displayed_data(user)
    if user.can_download_monitoree_data?
      assert_selector('#monitoree-excel-export', count: 1)
      assert_selector('#monitoree-nbs-export', count: 1)
    else
      assert_no_selector('#monitoree-excel-export')
      assert_no_selector('#monitoree-nbs-export')
    end

    # Everyone has access to patient details
    assert_selector('#patient-page')

    if user.can_view_patient_assessments?
      assert_selector('#assessments-table', count: 1)
    else
      assert_no_selector('#assessments-table')
    end

    if user.can_view_patient_laboratories?
      assert_selector('#labs-table', count: 1)
    else
      assert_no_selector('#labs-table')
    end

    if user.can_view_patient_close_contacts?
      assert_selector('#close-contacts-table', count: 1)
    else
      assert_no_selector('#close-contacts-table')
    end

    if user.can_modify_subject_status?
      assert_selector('#histories', count: 1)
      assert_selector('#monitoring-actions', count: 1)
    else
      assert_no_selector('#monitoring-actions')
      assert_no_selector('#histories')
    end
  end

  def move_to_household(_user_label, _patient_label, target_hoh_label)
    search_in_move_to_household_modal(target_hoh_label)
    select_in_move_to_household_modal(target_hoh_label)
    # TODO: Pagination and sorting tests.
  end

  def search_in_move_to_household_modal(target_hoh_label)
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

  def select_in_move_to_household_modal(target_hoh_label)
    new_responder_id = PATIENTS[target_hoh_label]['id']

    click_on 'Move To Household'
    fill_in 'search', with: PATIENTS[target_hoh_label]['last_name']
    assert page.has_button?('Select', count: 1)
    click_on 'Select'

    assert page.has_link?('Click here to view that monitoree', href: "/patients/#{new_responder_id}")
  end
end
