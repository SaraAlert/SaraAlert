# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'form_populator'
require_relative '../system_test_utils'

class MonitoreeEnrollmentFormValidator < ApplicationSystemTestCase
  @@monitoree_enrollment_form_populator = MonitoreeEnrollmentFormPopulator.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_enrollment_input_validation(monitoree)
    click_link 'Enroll New Monitoree'
    verify_input_validation_for_identification(monitoree['identification'])
    verify_input_validation_for_address(monitoree['address'])
    verify_input_validation_for_contact_info(monitoree['contact_info'])
    verify_input_validation_for_arrival_info(monitoree['arrival_info'])
    verify_input_validation_for_additional_planned_travel(monitoree['additional_planned_travel'])
    verify_input_validation_for_potential_exposure_info(monitoree['potential_exposure_info'])
  end

  def verify_input_validation_for_identification(identification)
    @@system_test_utils.go_to_next_page
    assert_selector 'div', text: 'Please enter a First Name.'
    assert_selector 'div', text: 'Please enter a Last Name.'
    assert_selector 'div', text: 'Please enter a date of birth.'
    fill_in 'date_of_birth', with: '01/05/3099'
    click_on 'Next'
    assert_selector 'div', text: 'Date can not be in the future.'
    refute_selector 'div', text: 'Please enter a date of birth.'
    fill_in 'date_of_birth', with: '02/31/1995'
    click_on 'Next'
    assert_selector 'div', text: 'Please enter a date of birth.'
    @@monitoree_enrollment_form_populator.populate_identification(identification, true)
    refute_selector 'div', text: 'Please enter a First Name.'
    refute_selector 'div', text: 'Please enter a Last Name.'
    refute_selector 'div', text: 'Please enter a date of birth.'
    refute_selector 'div', text: 'Date can not be in the future.'
  end

  def verify_input_validation_for_address(address)
    @@system_test_utils.go_to_next_page
    assert_selector 'div', text: 'Please enter first line of address.'
    assert_selector 'div', text: 'Please enter city of address.'
    assert_selector 'div', text: 'Please enter state of address.'
    assert_selector 'div', text: 'Please enter zip code of address.'
    refute_selector 'div', text: 'Please enter country of address.'
    click_on 'Home Address Outside USA (Foreign)'
    click_on 'Next'
    refute_selector 'div', text: 'Please enter first line of address.'
    assert_selector 'div', text: 'Please enter city of address.'
    refute_selector 'div', text: 'Please enter state of address.'
    refute_selector 'div', text: 'Please enter zip code of address.'
    assert_selector 'div', text: 'Please enter country of address.'
    click_on 'Home Address Within USA'
    @@monitoree_enrollment_form_populator.populate_address(address, true)
    refute_selector 'div', text: 'Please enter first line of address.'
    refute_selector 'div', text: 'Please enter city of address.'
    refute_selector 'div', text: 'Please enter state of address.'
    refute_selector 'div', text: 'Please enter zip code of address.'
    refute_selector 'div', text: 'Please enter country of address.'
  end

  def verify_input_validation_for_contact_info(contact_info)
    @@system_test_utils.go_to_next_page
    assert_selector 'div', text: 'Please indicate a preferred contact method.'
    select 'Telephone call', from: 'preferred_contact_method'
    click_on 'Next'
    refute_selector 'div', text: 'Please provide an email'
    refute_selector 'div', text: 'Please confirm email'
    assert_selector 'div', text: 'Please provide a primary telephone number'
    assert_selector 'div', text: 'Please indicate the primary phone type'
    select 'SMS Text-message', from: 'preferred_contact_method'
    click_on 'Next'
    refute_selector 'div', text: 'Please provide an email'
    refute_selector 'div', text: 'Please confirm email'
    assert_selector 'div', text: 'Please provide a primary telephone number'
    assert_selector 'div', text: 'Please indicate the primary phone type'
    select 'E-mailed Web Link', from: 'preferred_contact_method'
    click_on 'Next'
    assert_selector 'div', text: 'Please provide an email'
    assert_selector 'div', text: 'Please confirm email'
    refute_selector 'div', text: 'Please provide a primary telephone number'
    refute_selector 'div', text: 'Please indicate the primary phone type'
    fill_in 'email', with: 'email@eample.com'
    click_on 'Next'
    refute_selector 'div', text: 'Please provide an email'
    assert_selector 'div', text: 'Please confirm email'
    refute_selector 'div', text: 'Please provide a primary telephone number'
    refute_selector 'div', text: 'Please indicate the primary phone type'
    @@monitoree_enrollment_form_populator.populate_contact_info(contact_info, true)
    refute_selector 'div', text: 'Please provide an email'
    refute_selector 'div', text: 'Please confirm email'
    refute_selector 'div', text: 'Please provide a primary telephone number'
    refute_selector 'div', text: 'Please indicate the primary phone type'
  end

  def verify_input_validation_for_arrival_info(arrival_info)
    ## Uncomment when validation is implemented for departure and arrival dates
    # fill_in 'date_of_departure', with: '02/29/2001'
    # click_on 'Next'
    # assert_selector 'div', text: 'Please enter a valid date of departure.'
    # fill_in 'date_of_departure', with: '10/01/803290'
    # click_on 'Next'
    # assert_selector 'div', text: 'Please enter a valid date of departure.'
    # fill_in 'date_of_arrival', with: '11/31/2000'
    # click_on 'Next'
    # assert_selector 'div', text: 'Please enter a valid date of departure.'
    # fill_in 'date_of_arrival', with: '10/01/4000'
    # click_on 'Next'
    # assert_selector 'div', text: 'Please enter a valid date of departure.'
    @@monitoree_enrollment_form_populator.populate_arrival_info(arrival_info, true)
    refute_selector 'div', text: 'Please enter a valid date of departure.'
  end

  def verify_input_validation_for_additional_planned_travel(additional_planned_travel)
    ## Uncomment when validation is implemented for departure and arrival dates
    # fill_in 'start_date', with: '02/29/2001'
    # click_on 'Next'
    # assert_selector 'div', text: 'Please enter a valid start date.'
    # fill_in 'start_date', with: '10/01/803290'
    # click_on 'Next'
    # assert_selector 'div', text: 'Please enter a valid start date.'
    # fill_in 'end_date', with: '11/31/2000'
    # click_on 'Next'
    # assert_selector 'div', text: 'Please enter a valid end date.'
    # fill_in 'end_date', with: '10/01/4000'
    # click_on 'Next'
    # assert_selector 'div', text: 'Please enter a valid end date.'
    @@monitoree_enrollment_form_populator.populate_additional_planned_travel(additional_planned_travel, true)
    refute_selector 'div', text: 'Please enter a valid start date.'
    refute_selector 'div', text: 'Please enter a valid end date.'
  end

  def verify_input_validation_for_potential_exposure_info(potential_exposure_info)
    @@system_test_utils.go_to_next_page
    assert_selector 'div', text: 'Please enter a last date of exposure.'
    fill_in 'last_date_of_exposure', with: '11/31/2000'
    click_on 'Next'
    assert_selector 'div', text: 'Please enter a last date of exposure.'
    fill_in 'last_date_of_exposure', with: '10/01/5398'
    click_on 'Next'
    assert_selector 'div', text: 'Date can not be in the future.'
    @@monitoree_enrollment_form_populator.populate_potential_exposure_info(potential_exposure_info, true)
    refute_selector 'div', text: 'Please enter a last date of exposure.'
    refute_selector 'div', text: 'Date can not be in the future.'
  end
end
