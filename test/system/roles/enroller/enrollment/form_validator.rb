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
    verify_input_validation_for_contact_information(monitoree['contact_information'])
    verify_input_validation_for_arrival_information(monitoree['arrival_information'])
    verify_input_validation_for_planned_travel(monitoree['planned_travel'])
    verify_input_validation_for_potential_exposure_information(monitoree['potential_exposure_information'])
  end

  def verify_input_validation_for_identification(identification)
    @@system_test_utils.go_to_next_page
    verify_text_displayed('Please enter a First Name')
    verify_text_displayed('Please enter a Last Name')
    verify_text_displayed('Please enter a Date of Birth')
    @@enrollment_form.populate_enrollment_step(:identification, identification)
    verify_text_not_displayed('Please enter a First Name')
    verify_text_not_displayed('Please enter a Last Name')
    verify_text_not_displayed('Please enter a Date of Birth')
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

  def verify_input_validation_for_contact_information(contact_information)
    select 'Telephone call', from: 'preferred_contact_method'
    click_on 'Next'
    verify_text_not_displayed('Please provide an Email or change Preferred Reporting Method')
    verify_text_not_displayed('Please confirm Email')
    verify_text_displayed('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
    select 'SMS Text-message', from: 'preferred_contact_method'
    click_on 'Next'
    verify_text_not_displayed('Please provide an Email or change Preferred Reporting Method')
    verify_text_not_displayed('Please confirm Email')
    verify_text_displayed('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
    select 'E-mailed Web Link', from: 'preferred_contact_method'
    click_on 'Next'
    verify_text_displayed('Please provide an Email or change Preferred Reporting Method')
    verify_text_displayed('Please confirm Email')
    verify_text_not_displayed('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
    fill_in 'email', with: 'email@eample.com'
    click_on 'Next'
    verify_text_not_displayed('Please provide an Email or change Preferred Reporting Method')
    verify_text_displayed('Please confirm Email')
    verify_text_not_displayed('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
    @@enrollment_form.populate_enrollment_step(:contact_information, contact_information)
    verify_text_not_displayed('Please provide an Email or change Preferred Reporting Method')
    verify_text_not_displayed('Please confirm Email')
    verify_text_not_displayed('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
  end

  def verify_input_validation_for_arrival_information(arrival_information)
    @@enrollment_form.populate_enrollment_step(:arrival_information, arrival_information)
  end

  def verify_input_validation_for_planned_travel(planned_travel)
    @@enrollment_form.populate_enrollment_step(:planned_travel, planned_travel)
  end

  def verify_input_validation_for_potential_exposure_information(potential_exposure_information)
    @@system_test_utils.go_to_next_page
    verify_text_displayed('Please enter a Last Date of Exposure OR turn on Continuous Exposure')
    fill_in 'last_date_of_exposure', with: rand(30).days.ago.strftime('%m/%d/%Y')
    fill_in 'jurisdiction_id', with: ''
    click_on 'Next'
    verify_text_displayed('Please enter a valid Assigned Jurisdiction')
    fill_in 'jurisdiction_id', with: 'fake jurisdiction'
    click_on 'Next'
    verify_text_displayed('Please enter a valid Assigned Jurisdiction')
    fill_in 'jurisdiction_id', with: 'USA'
    click_on 'Next'
    verify_text_displayed('Please enter a valid Assigned Jurisdiction')
    fill_in 'jurisdiction_id', with: 'USA, State 1, County 1'
    fill_in 'assigned_user', with: '-8.5'
    assert_not_equal('-8.5', page.find_field('assigned_user').value)
    fill_in 'assigned_user', with: '1000000'
    assert_not_equal('1000000', page.find_field('assigned_user').value)
    fill_in 'assigned_user', with: 'asdf'
    assert_not_equal('asdf', page.find_field('assigned_user').value)
    fill_in 'assigned_user', with: 'W(#*&R#(W&'
    assert_not_equal('W(#*&R#(W&', page.find_field('assigned_user').value)
    @@enrollment_form.populate_enrollment_step(:potential_exposure_information, potential_exposure_information)
    verify_text_not_displayed('Please enter a Last Date of Exposure OR turn on Continuous Exposure')
  end

  def verify_text_displayed(text)
    assert page.has_content?(text), "Monitoree enrollment input validation - should display error message: #{text}"
  end

  def verify_text_not_displayed(text)
    assert page.has_no_content?(text), "Monitoree enrollment input validation - should not display error message: #{text}"
  end
end
