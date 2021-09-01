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
    page.assert_text('Please enter a First Name')
    page.assert_text('Please enter a Last Name')
    page.assert_text('Please enter a Date of Birth')
    @@enrollment_form.populate_enrollment_step(:identification, identification)
    page.assert_no_text('Please enter a First Name')
    page.assert_no_text('Please enter a Last Name')
    page.assert_no_text('Please enter a Date of Birth')
  end

  def verify_input_validation_for_address(address)
    @@system_test_utils.go_to_next_page
    page.assert_text('Please enter first line of address')
    page.assert_text('Please enter city of address')
    page.assert_text('Please enter state of address')
    page.assert_text('Please enter zip code of address')
    page.assert_no_text('Please enter country of address')
    click_on 'Home Address Outside USA (Foreign)'
    click_on 'Next'
    page.assert_no_text('Please enter first line of address')
    page.assert_text('Please enter city of address')
    page.assert_no_text('Please enter state of address')
    page.assert_no_text('Please enter zip code of address')
    page.assert_text('Please enter country of address')
    click_on 'Home Address Within USA'
    @@enrollment_form.populate_enrollment_step(:address, address)
    page.assert_no_text('Please enter first line of address')
    page.assert_no_text('Please enter city of address')
    page.assert_no_text('Please enter state of address')
    page.assert_no_text('Please enter zip code of address')
    page.assert_no_text('Please enter country of address')
  end

  def verify_input_validation_for_contact_information(contact_information)
    select 'Telephone call', from: 'preferred_contact_method'
    click_on 'Next'
    page.assert_no_text('Please provide an Email or change Preferred Reporting Method')
    page.assert_no_text('Please confirm Email')
    page.assert_text('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
    select 'SMS Text-message', from: 'preferred_contact_method'
    click_on 'Next'
    page.assert_no_text('Please provide an Email or change Preferred Reporting Method')
    page.assert_no_text('Please confirm Email')
    page.assert_text('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
    select 'E-mailed Web Link', from: 'preferred_contact_method'
    click_on 'Next'
    page.assert_text('Please provide an Email or change Preferred Reporting Method')
    page.assert_text('Please confirm Email')
    page.assert_no_text('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
    fill_in 'email', with: 'email@eample.com'
    click_on 'Next'
    page.assert_no_text('Please provide an Email or change Preferred Reporting Method')
    page.assert_text('Please confirm Email')
    page.assert_no_text('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
    @@enrollment_form.populate_enrollment_step(:contact_information, contact_information)
    page.assert_no_text('Please provide an Email or change Preferred Reporting Method')
    page.assert_no_text('Please confirm Email')
    page.assert_no_text('Please provide a Primary Telephone Number, or change Preferred Reporting Method.')
  end

  def verify_input_validation_for_arrival_information(arrival_information)
    @@enrollment_form.populate_enrollment_step(:arrival_information, arrival_information)
  end

  def verify_input_validation_for_planned_travel(planned_travel)
    @@enrollment_form.populate_enrollment_step(:planned_travel, planned_travel)
  end

  def verify_input_validation_for_potential_exposure_information(potential_exposure_information)
    @@system_test_utils.go_to_next_page
    page.assert_text('Please enter a Last Date of Exposure OR turn on Continuous Exposure')
    fill_in 'last_date_of_exposure', with: 5.days.ago.strftime('%m/%d/%Y')
    fill_in 'jurisdiction_id', with: '' # clear out jurisdiction to so that there is at least one validation error
    click_on 'Next'
    page.assert_no_text('Please enter a Last Date of Exposure OR turn on Continuous Exposure')
    fill_in 'last_date_of_exposure', with: ''
    click_on 'Next'
    page.assert_text('Please enter a Last Date of Exposure OR turn on Continuous Exposure')
    page.find('label', text: 'CONTINUOUS EXPOSURE').click
    page.assert_no_text('Please enter a Last Date of Exposure OR turn on Continuous Exposure')
    page.assert_text('Please enter a valid Assigned Jurisdiction')
    fill_in 'jurisdiction_id', with: 'fake jurisdiction'
    click_on 'Next'
    page.assert_text('Please enter a valid Assigned Jurisdiction')
    fill_in 'jurisdiction_id', with: 'USA'
    click_on 'Next'
    page.assert_text('Please enter a valid Assigned Jurisdiction')
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
    click_on 'OK' # confirm jurisdiction change
    page.assert_no_text('Please enter a Last Date of Exposure OR turn on Continuous Exposure')

    # isolation fields
    @@system_test_utils.wait_for_enrollment_page_transition
    click_on 'edit-identification-btn'
    @@system_test_utils.wait_for_enrollment_page_transition
    # This is a Capybara/Selenium method so we disable Rubocop.
    # rubocop:disable Rails/DynamicFindBy
    page.find_by_id('workflow_wrapper').first(:xpath, './/div//div//div//div//div//input').set('Isolation (case)').send_keys(:enter)
    # rubocop:enable Rails/DynamicFindBy
    click_on 'Next'
    @@system_test_utils.wait_for_enrollment_page_transition
    click_on 'edit-case_information-btn'
    fill_in 'jurisdiction_id', with: '' # clear out jurisdiction to so that there is at least one validation error
    click_on 'Next'
    page.assert_text('Please enter a Symptom Onset Date AND/OR a positive lab result.')
    fill_in 'symptom_onset', with: 3.days.ago.strftime('%m/%d/%Y')
    click_on 'Next'
    page.assert_no_text('Please enter a Symptom Onset Date AND/OR a positive lab result.')
    fill_in 'symptom_onset', with: ''
    click_on 'Next'
    page.assert_text('Please enter a Symptom Onset Date AND/OR a positive lab result.')
    click_on 'Enter Lab Result'
    assert page.has_button?('Create', disabled: true)
    fill_in 'specimen_collection', with: 2.days.ago.strftime('%m/%d/%Y')
    click_on 'Create'
    click_on 'Next'
    page.assert_no_text('Please enter a Symptom Onset Date AND/OR a positive lab result.')
    fill_in 'symptom_onset', with: 3.days.ago.strftime('%m/%d/%Y')
    click_on 'Next'
    page.assert_no_text('Please enter a Symptom Onset Date AND/OR a positive lab result.')
  end
end
