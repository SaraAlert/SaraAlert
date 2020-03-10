# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../system_test_utils'

class MonitoreeEnrollmentInfoPageVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_monitoree_info(monitoree)
    verify_identification(monitoree['identification'])
    verify_address(monitoree['address'])
    verify_contact_info(monitoree['contact_info'])
    verify_arrival_info(monitoree['arrival_info'])
    verify_additional_planned_travel(monitoree['additional_planned_travel'])
    verify_potential_exposure_info(monitoree['potential_exposure_info'])
  end

  def verify_monitoree_info_as_group_member(existing_monitoree, new_monitoree)
    verify_identification(new_monitoree['identification'])
    verify_address(existing_monitoree['address'])
    verify_contact_info(existing_monitoree['contact_info'])
    verify_arrival_info(existing_monitoree['arrival_info'])
    verify_additional_planned_travel(existing_monitoree['additional_planned_travel'])
    verify_potential_exposure_info(existing_monitoree['potential_exposure_info'])
  end

  def verify_identification(identification)
    verify_name_field(identification['first_name'])
    verify_name_field(identification['middle_name'])
    verify_name_field(identification['last_name'])
    verify_date_field(identification['date_of_birth'])
    verify_monitoree_age_field(identification['date_of_birth'])
    verify_text_field(identification['sex'])
    verify_checkbox_field(identification, 'white', 'White')
    verify_checkbox_field(identification, 'black_or_african_american', 'Black or African American')
    verify_checkbox_field(identification, 'american_indian_or_alaska_native', 'American Indian or Alaska Native')
    verify_checkbox_field(identification, 'asian', 'Asian')
    verify_checkbox_field(identification, 'native_hawaiian_or_other_pacific_islander', 'Native Hawaiian or Other Pacific Islander')
    verify_text_field(identification['ethnicity'])
    verify_text_field(identification['language'])
    verify_text_field(identification['nationality'])
    verify_text_field(identification['user_defined_id_statelocal'])
    verify_text_field(identification['user_defined_id_cdc'])
    verify_text_field(identification['user_defined_id_nndss'])
  end

  def verify_address(address)
    verify_text_field(address['address_line_1'])
    verify_text_field(address['address_line_2'])
    verify_text_field(address['address_city'])
    verify_state_field(address['address_state'])
    verify_text_field(address['address_zip'])
    verify_text_field(address['address_county'])
    verify_text_field(address['foreign_address_line_1'])
    verify_text_field(address['foreign_address_line_2'])
    verify_text_field(address['foreign_address_city'])
    verify_text_field(address['foreign_address_country'])
    verify_text_field(address['foreign_address_zip'])
  end

  def verify_contact_info(contact_info)
    verify_text_field(contact_info['primary_telephone'])
    verify_text_field(contact_info['primary_telephone_type'])
    verify_text_field(contact_info['email'])
    verify_text_field(contact_info['preferred_contact_method'])
    verify_text_field(contact_info['preferred_contact_time'])
  end

  def verify_arrival_info(arrival_info)
    if arrival_info
      verify_text_field(arrival_info['port_of_origin'])
      verify_date_field(arrival_info['date_of_departure'])
      verify_text_field(arrival_info['flight_or_vessel_number'])
      verify_text_field(arrival_info['flight_or_vessel_carrier'])
      verify_text_field(arrival_info['port_of_entry_into_usa'])
      verify_date_field(arrival_info['date_of_arrival'])
    end
  end

  def verify_additional_planned_travel(additional_planned_travel)
    if additional_planned_travel
      verify_text_field(additional_planned_travel['additional_planned_travel_type'])
      if additional_planned_travel['additional_planned_travel_type'] == 'Domestic'
        verify_state_field(additional_planned_travel['additional_planned_travel_destination_state'])
      end
      if additional_planned_travel['additional_planned_travel_type'] == 'International'
        verify_text_field(additional_planned_travel['additional_planned_travel_destination_country'])
      end
      verify_text_field(additional_planned_travel['additional_planned_travel_port_of_departure'])
      verify_date_field(additional_planned_travel['start_date'])
      verify_date_field(additional_planned_travel['end_date'])
    end
  end

  def verify_potential_exposure_info(potential_exposure_info)
    verify_date_field(potential_exposure_info['last_exposure_date'])
    verify_text_field(potential_exposure_info['potential_exposure_location'])
    verify_text_field(potential_exposure_info['potential_exposure_country'])
    verify_text_field(potential_exposure_info['contact_of_known_case_id'])
    verify_exposure_risk_factor_with_custom_label(potential_exposure_info, 'contact_of_known_case', 'CLOSE CONTACT WITH A KNOWN CASE')
    verify_exposure_risk_factor(potential_exposure_info, 'travel_to_affected_country_or_area')
    verify_exposure_risk_factor(potential_exposure_info, 'was_in_health_care_facility_with_known_cases')
    verify_exposure_risk_factor(potential_exposure_info, 'laboratory_personel')
    verify_exposure_risk_factor(potential_exposure_info, 'healthcare_personel')
    verify_exposure_risk_factor(potential_exposure_info, 'crew_on_passenger_or_cargo_flight')
  end

  def verify_name_field(value)
    assert_selector 'h5', text: value if value
  end

  def verify_text_field(value)
    assert_selector 'span', text: value if value
  end

  def verify_date_field(value)
    assert_selector 'span', text: value[6..9] + '-' + value[0..1] + '-' + value[3..4] if value
  end

  def verify_monitoree_age_field(value)
    assert_selector 'span', text: @@system_test_utils.calculate_age(value) if value
  end

  def verify_state_field(value)
    assert_selector 'span', text: value if value
  end

  def verify_exposure_risk_factor(data, field)
    verify_checkbox_field(data, field, field.upcase.gsub('_', ' '))
  end

  def verify_exposure_risk_factor_with_custom_label(data, field, label)
    verify_checkbox_field(data, field, label)
  end

  def verify_checkbox_field(data, field, value)
    data[field] ? (assert_selector 'span', text: value) : (refute_selector 'span', text: value)
  end
end
