# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'form_populator'
require_relative '../system_test_utils'

class MonitoreeEnrollmentFormVerifier < ApplicationSystemTestCase
  @@monitoree_enrollment_form_populator = MonitoreeEnrollmentFormPopulator.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_form_data_after_navigation(monitoree)
    click_link 'Enroll New Monitoree'
    @@monitoree_enrollment_form_populator.populate_identification(monitoree['identification'], true)
    @@system_test_utils.go_to_prev_page
    verify_form_data_consistency_for_identification(monitoree['identification'])
    @@system_test_utils.go_to_next_page
    @@monitoree_enrollment_form_populator.populate_address(monitoree['address'], true)
    @@system_test_utils.go_to_prev_page
    verify_form_data_consistency_for_address(monitoree['address'])
    @@system_test_utils.go_to_next_page
    @@monitoree_enrollment_form_populator.populate_contact_info(monitoree['contact_info'], true)
    @@system_test_utils.go_to_prev_page
    verify_form_data_consistency_for_contact_info(monitoree['contact_info'])
    @@system_test_utils.go_to_next_page
    @@monitoree_enrollment_form_populator.populate_arrival_info(monitoree['arrival_info'], true)
    @@system_test_utils.go_to_prev_page
    verify_form_data_consistency_for_arrival_info(monitoree['arrival_info'])
    @@system_test_utils.go_to_next_page
    @@monitoree_enrollment_form_populator.populate_additional_planned_travel(monitoree['additional_planned_travel'], true)
    @@system_test_utils.go_to_prev_page
    verify_form_data_consistency_for_additional_planned_travel(monitoree['additional_planned_travel'])
    @@system_test_utils.go_to_next_page
    @@monitoree_enrollment_form_populator.populate_potential_exposure_info(monitoree['potential_exposure_info'], true)
    @@system_test_utils.go_to_prev_page
    verify_form_data_consistency_for_potential_exposure_info(monitoree['potential_exposure_info'])
    @@system_test_utils.go_to_next_page
  end

  def verify_form_data_consistency_for_identification(identification)
    verify_form_data_for_input_field(identification, 'first_name')
    verify_form_data_for_input_field(identification, 'middle_name')
    verify_form_data_for_input_field(identification, 'last_name')
    verify_form_data_for_date_input_field(identification, 'date_of_birth')
    verify_form_data_for_input_field(identification, 'sex')
    verify_form_data_for_checkbox_input_field(identification, 'white')
    verify_form_data_for_checkbox_input_field(identification, 'black_or_african_american')
    verify_form_data_for_checkbox_input_field(identification, 'american_indian_or_alaska_native')
    verify_form_data_for_checkbox_input_field(identification, 'asian')
    verify_form_data_for_checkbox_input_field(identification, 'native_hawaiian_or_other_pacific_islander')
    verify_form_data_for_input_field(identification, 'ethnicity')
    verify_form_data_for_input_field(identification, 'primary_language')
    verify_form_data_for_input_field(identification, 'secondary_language')
    verify_form_data_for_checkbox_input_field(identification, 'interpretation_required')
    verify_form_data_for_input_field(identification, 'nationality')
    verify_form_data_for_input_field(identification, 'user_defined_id_statelocal')
    verify_form_data_for_input_field(identification, 'user_defined_id_cdc')
    verify_form_data_for_input_field(identification, 'user_defined_id_nndss')
  end

  def verify_form_data_consistency_for_address(address)
    click_on 'Home Address Within USA'
    verify_form_data_for_input_field(address, 'address_line_1')
    verify_form_data_for_input_field(address, 'address_city')
    verify_form_data_for_state_input_field(address, 'address_state')
    verify_form_data_for_input_field(address, 'address_line_2')
    verify_form_data_for_input_field(address, 'address_zip')
    verify_form_data_for_input_field(address, 'address_county')
    verify_form_data_for_input_field(address, 'monitored_address_line_1')
    verify_form_data_for_input_field(address, 'monitored_address_line_2')
    verify_form_data_for_input_field(address, 'monitored_address_city')
    verify_form_data_for_state_input_field(address, 'monitored_address_state')
    verify_form_data_for_input_field(address, 'monitored_address_zip')
    verify_form_data_for_input_field(address, 'monitored_address_county')
    click_on 'Home Address Outside USA (Foreign)'
    verify_form_data_for_input_field(address, 'foreign_address_line_1')
    verify_form_data_for_input_field(address, 'foreign_address_city')
    verify_form_data_for_input_field(address, 'foreign_address_country')
    verify_form_data_for_input_field(address, 'foreign_address_line_2')
    verify_form_data_for_input_field(address, 'foreign_address_zip')
    verify_form_data_for_input_field(address, 'foreign_address_line_3')
    verify_form_data_for_input_field(address, 'foreign_address_state')
    verify_form_data_for_input_field(address, 'foreign_monitored_address_line_1')
    verify_form_data_for_input_field(address, 'foreign_monitored_address_city')
    verify_form_data_for_state_input_field(address, 'foreign_monitored_address_state')
    verify_form_data_for_input_field(address, 'foreign_monitored_address_line_2')
    verify_form_data_for_input_field(address, 'foreign_monitored_address_zip')
    verify_form_data_for_input_field(address, 'foreign_monitored_address_county')
  end

  def verify_form_data_consistency_for_contact_info(contact_info)
    verify_form_data_for_input_field(contact_info, 'primary_telephone')
    verify_form_data_for_input_field(contact_info, 'primary_telephone_type')
    verify_form_data_for_input_field(contact_info, 'secondary_telephone')
    verify_form_data_for_input_field(contact_info, 'secondary_telephone_type')
    verify_form_data_for_input_field(contact_info, 'email')
    verify_form_data_for_input_field(contact_info, 'confirm_email')
    verify_form_data_for_input_field(contact_info, 'preferred_contact_method')
    verify_form_data_for_input_field(contact_info, 'preferred_contact_time')
  end

  def verify_form_data_consistency_for_arrival_info(arrival_info)
    verify_form_data_for_input_field(arrival_info, 'port_of_origin')
    verify_form_data_for_date_input_field(arrival_info, 'date_of_departure')
    verify_form_data_for_input_field(arrival_info, 'source_of_report')
    verify_form_data_for_input_field(arrival_info, 'flight_or_vessel_number')
    verify_form_data_for_input_field(arrival_info, 'flight_or_vessel_carrier')
    verify_form_data_for_input_field(arrival_info, 'port_of_entry_into_usa')
    verify_form_data_for_date_input_field(arrival_info, 'date_of_arrival')
    verify_form_data_for_input_field(arrival_info, 'travel_related_notes')
  end

  def verify_form_data_consistency_for_additional_planned_travel(additional_planned_travel)
    verify_form_data_for_input_field(additional_planned_travel, 'additional_planned_travel_type')
    verify_form_data_for_input_field(additional_planned_travel, 'additional_planned_travel_destination')
    verify_form_data_for_state_input_field(additional_planned_travel, 'additional_planned_travel_destination_state')
    verify_form_data_for_input_field(additional_planned_travel, 'additional_planned_travel_destination_country')
    verify_form_data_for_input_field(additional_planned_travel, 'additional_planned_travel_port_of_departure')
    verify_form_data_for_date_input_field(additional_planned_travel, 'additional_planned_travel_start_date')
    verify_form_data_for_date_input_field(additional_planned_travel, 'additional_planned_travel_end_date')
    verify_form_data_for_input_field(additional_planned_travel, 'additional_planned_travel_related_notes')
  end

  def verify_form_data_consistency_for_potential_exposure_info(potential_exposure_info)
    verify_form_data_for_date_input_field(potential_exposure_info, 'last_date_of_exposure')
    verify_form_data_for_input_field(potential_exposure_info, 'potential_exposure_location')
    verify_form_data_for_input_field(potential_exposure_info, 'potential_exposure_country')
    verify_form_data_for_checkbox_input_field_with_custom_label(potential_exposure_info, 'travel_to_affected_country_or_area', 'CLOSE CONTACT WITH A KNOWN CASE')
    verify_form_data_for_checkbox_input_field(potential_exposure_info, 'travel_to_affected_country_or_area')
    verify_form_data_for_checkbox_input_field(potential_exposure_info, 'was_in_health_care_facility_with_known_cases')
    verify_form_data_for_checkbox_input_field(potential_exposure_info, 'laboratory_personnel')
    verify_form_data_for_checkbox_input_field(potential_exposure_info, 'healthcare_personnel')
    verify_form_data_for_checkbox_input_field(potential_exposure_info, 'crew_on_passenger_or_cargo_flight')
    verify_form_data_for_input_field(potential_exposure_info, 'contact_of_known_case_id')
    verify_form_data_for_input_field(potential_exposure_info, 'exposure_risk_assessment')
    verify_form_data_for_input_field(potential_exposure_info, 'monitoring_plan')
    verify_form_data_for_input_field(potential_exposure_info, 'exposure_notes')
  end

  def verify_form_data_for_input_field(data, field)
    assert_equal(data[field], find('#' + field)['value'], field + ' mismatch') if data[field]
  end

  def verify_form_data_for_date_input_field(data, field)
    assert_equal(@@system_test_utils.format_date(data[field]), find('#' + field)['value'], field + ' mismatch') if data[field]
  end

  def verify_form_data_for_state_input_field(data, field)
    assert_equal(data[field], find('#' + field)['value'], field + ' mismatch') if data[field]
  end

  def verify_form_data_for_checkbox_input_field(data, field)
    verify_form_data_for_checkbox_input_field_with_custom_label(data, field, field.upcase.gsub('_', ' '))
  end

  def verify_form_data_for_checkbox_input_field_with_custom_label(data, field, label)
    # need to figure out how to get value of checkbox input from DOM
    # assert_equal(data[field], find("label", text: label)) if data[field]
  end
end
