# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'form'
require_relative '../../../lib/system_test_utils'

class EnrollmentFormValidator < ApplicationSystemTestCase
  @@enrollment_form = EnrollmentForm.new(nil)
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
    verify_text_displayed('Please enter a First Name')
    verify_text_displayed('Please enter a Last Name')
    verify_text_displayed('Please enter a date of birth')
    fill_in 'date_of_birth', with: '01/05/3099'
    @@system_test_utils.go_to_next_page(false)
    verify_text_displayed('Date can not be in the future')
    verify_text_not_displayed('Please enter a date of birth')
    fill_in 'date_of_birth', with: '02/31/1995'
    @@system_test_utils.go_to_next_page(false)
    verify_text_displayed('Please enter a date of birth')
    @@enrollment_form.populate_enrollment_step(:identification, identification)
    verify_text_not_displayed('Please enter a First Name')
    verify_text_not_displayed('Please enter a Last Name')
    verify_text_not_displayed('Please enter a date of birth')
    verify_text_not_displayed('Date can not be in the future')
  end

  def verify_input_validation_for_address(address)
    @@system_test_utils.go_to_next_page
    verify_text_displayed('Please enter first line of address')
    verify_text_displayed('Please enter city of address')
    verify_text_displayed('Please enter state of address')
    verify_text_displayed('Please enter zip code of address')
    verify_text_not_displayed('Please enter country of address')
    click_on 'Home Address Outside USA (Foreign)'
    click_on 'Next'
    verify_text_not_displayed('Please enter first line of address')
    verify_text_displayed('Please enter city of address')
    verify_text_not_displayed('Please enter state of address')
    verify_text_not_displayed('Please enter zip code of address')
    verify_text_displayed('Please enter country of address')
    click_on 'Home Address Within USA'
    @@enrollment_form.populate_enrollment_step(:address, address)
    verify_text_not_displayed('Please enter first line of address')
    verify_text_not_displayed('Please enter city of address')
    verify_text_not_displayed('Please enter state of address')
    verify_text_not_displayed('Please enter zip code of address')
    verify_text_not_displayed('Please enter country of address')
  end

  def verify_input_validation_for_contact_info(contact_info)
    select 'Telephone call', from: 'preferred_contact_method'
    click_on 'Next'
    verify_text_not_displayed('Please provide an email')
    verify_text_not_displayed('Please confirm email')
    verify_text_displayed('Please provide a primary telephone number')
    select 'SMS Text-message', from: 'preferred_contact_method'
    click_on 'Next'
    verify_text_not_displayed('Please provide an email')
    verify_text_not_displayed('Please confirm email')
    verify_text_displayed('Please provide a primary telephone number')
    select 'E-mailed Web Link', from: 'preferred_contact_method'
    click_on 'Next'
    verify_text_displayed('Please provide an email')
    verify_text_displayed('Please confirm email')
    verify_text_not_displayed('Please provide a primary telephone number')
    fill_in 'email', with: 'email@eample.com'
    click_on 'Next'
    verify_text_not_displayed('Please provide an email')
    verify_text_displayed('Please confirm email')
    verify_text_not_displayed('Please provide a primary telephone number')
    @@enrollment_form.populate_enrollment_step(:contact_info, contact_info)
    verify_text_not_displayed('Please provide an email')
    verify_text_not_displayed('Please confirm email')
    verify_text_not_displayed('Please provide a primary telephone number')
  end

  def verify_input_validation_for_arrival_info(arrival_info)
    @@enrollment_form.populate_enrollment_step(:arrival_info, arrival_info)
    verify_text_not_displayed('Please enter a valid date of departure')
  end

  def verify_input_validation_for_additional_planned_travel(additional_planned_travel)
    @@enrollment_form.populate_enrollment_step(:additional_planned_travel, additional_planned_travel)
    verify_text_not_displayed('Please enter a valid start date')
    verify_text_not_displayed('Please enter a valid end date')
  end

  def verify_input_validation_for_potential_exposure_info(potential_exposure_info)
    @@system_test_utils.go_to_next_page
    verify_text_displayed('Please enter a last date of exposure')
    fill_in 'last_date_of_exposure', with: '11/31/2000'
    click_on 'Next'
    verify_text_displayed('Please enter a last date of exposure')
    fill_in 'last_date_of_exposure', with: '10/01/5398'
    click_on 'Next'
    verify_text_displayed('Date can not be in the future')
    fill_in 'last_date_of_exposure', with: '04/20/2020'
    fill_in 'jurisdiction_id', with: ''
    click_on 'Next'
    verify_text_displayed('Please enter a valid jurisdiction')
    fill_in 'jurisdiction_id', with: 'fake jurisdiction'
    click_on 'Next'
    verify_text_displayed('Please enter a valid jurisdiction')
    fill_in 'jurisdiction_id', with: 'USA'
    click_on 'Next'
    verify_text_displayed('Please enter a valid jurisdiction')
    fill_in 'jurisdiction_id', with: 'USA, State 1, County 1'
    fill_in 'assigned_user', with: '-8.5'
    assert_not_equal('-8.5', page.find_field('assignedUser').value)
    fill_in 'assigned_user', with: '10000'
    assert_not_equal('10000', page.find_field('assignedUser').value)
    fill_in 'assigned_user', with: 'asdf'
    assert_not_equal('asdf', page.find_field('assignedUser').value)
    fill_in 'assigned_user', with: 'W(#*&R#(W&'
    assert_not_equal('W(#*&R#(W&', page.find_field('assignedUser').value)
    @@enrollment_form.populate_enrollment_step(:potential_exposure_info, potential_exposure_info)
    verify_text_not_displayed('Please enter a last date of exposure')
    verify_text_not_displayed('Date can not be in the future')
  end

  def verify_text_displayed(text)
    assert page.has_content?(text), "Monitoree enrollment input validation - should display error message: #{text}"
  end

  def verify_text_not_displayed(text)
    assert page.has_no_content?(text), "Monitoree enrollment input validation - should not display error message: #{text}"
  end
end
