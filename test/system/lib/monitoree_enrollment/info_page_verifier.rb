# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../system_test_utils'

class MonitoreeEnrollmentInfoPageVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_monitoree_info(monitoree, isEpi=false)
    find('#patient-info-header').click if isEpi
    verify_identification(monitoree['identification'])
    verify_address(monitoree['address'])
    verify_contact_info(monitoree['contact_info'])
    verify_arrival_info(monitoree['arrival_info'])
    verify_additional_planned_travel(monitoree['additional_planned_travel'])
    verify_potential_exposure_info(monitoree['potential_exposure_info'])
  end

  def verify_monitoree_info_as_group_member(existing_monitoree, new_monitoree, isEpi=false)
    find('#patient-info-header').click if isEpi
    verify_identification(new_monitoree['identification'])
    verify_address(existing_monitoree['address'])
    verify_contact_info(existing_monitoree['contact_info'])
    verify_arrival_info(existing_monitoree['arrival_info'])
    verify_additional_planned_travel(existing_monitoree['additional_planned_travel'])
    verify_potential_exposure_info(existing_monitoree['potential_exposure_info'])
  end

  def verify_identification(identification)
    text_fields = ['first_name', 'middle_name', 'last_name', 'sex', 'ethnicity', 'language', 'nationality',
                   'user_defined_id_statelocal', 'user_defined_id_cdc', 'user_defined_id_nndss']
    checkbox_fields = {
      white: 'White',
      black_or_african_american: 'Black or African American',
      american_indian_or_alaska_native: 'American Indian or Alaska Native',
      asian: 'Asian',
      native_hawaiian_or_other_pacific_islander: 'Native Hawaiian or Other Pacific Islander'
    }
    verify_text_fields(identification, text_fields) 
    verify_date_fields(identification, ['date_of_birth'])
    verify_age_fields(identification, ['date_of_birth'])
    verify_checkbox_fields(identification, checkbox_fields)
  end

  def verify_address(address)
    text_fields = ['address_line_1', 'address_line_2', 'address_city', 'address_state', 'address_zip', 'address_county',
                  'foreign_address_line_1', 'foreign_address_line_2', 'foreign_address_city', 'foreign_address_country', 'foreign_address_zip']
    verify_text_fields(address, text_fields)
  end

  def verify_contact_info(contact_info)
    text_fields = ['primary_telephone', 'primary_telephone_type', 'email', 'preferred_contact_method', 'preferred_contact_time']
    verify_text_fields(contact_info, text_fields)
  end

  def verify_arrival_info(arrival_info)
    if arrival_info
      text_fields = ['port_of_origin', 'flight_or_vessel_number', 'flight_or_vessel_carrier', 'port_of_entry_into_usa']
      verify_text_fields(arrival_info, text_fields)
      verify_date_fields(arrival_info, ['date_of_departure', 'date_of_arrival'])
    end
  end

  def verify_additional_planned_travel(additional_planned_travel)
    if additional_planned_travel
      text_fields = ['additional_planned_travel_type', 'additional_planned_travel_port_of_departure']
      text_fields.push('additional_planned_travel_destination_state') if additional_planned_travel['additional_planned_travel_type'] == 'Domestic'
      text_fields.push('additional_planned_travel_destination_country') if additional_planned_travel['additional_planned_travel_type'] == 'International'
      date_fields = ['additional_planned_travel_start_date', 'additional_planned_travel_end_date']
      verify_text_fields(additional_planned_travel, text_fields)
      verify_date_fields(additional_planned_travel, date_fields)
    end
  end

  def verify_potential_exposure_info(potential_exposure_info)
    text_fields = ['potential_exposure_location', 'potential_exposure_country', 'contact_of_known_case_id']
    checkbox_fields = {
      contact_of_known_case: 'CLOSE CONTACT WITH A KNOWN CASE',
      was_in_health_care_facility_with_known_cases: 'WAS IN HEALTH CARE FACILITY WITH KNOWN CASES',
      laboratory_personel: 'LABORATORY_PERSONEL',
      healthcare_personel: 'HEALTHCARE_PERSONEL',
      crew_on_passenger_or_cargo_flight: 'CREW ON PASSENGER OR CARGO FLIGHT',
      member_of_a_common_exposure_cohort: 'MEMBER OF A COMMON EXPOSURE COHORT'
    }
    verify_text_fields(potential_exposure_info, text_fields)
    verify_date_fields(potential_exposure_info, ['last_exposure_date'])
    verify_checkbox_fields(potential_exposure_info, checkbox_fields)
  end
  
  def verify_text_fields(data, fields)
    fields.each { |field|
      assert page.has_content?(data[field]), @@system_test_utils.get_err_msg('Monitoree details', field, data[field]) if data.has_key?(field)
    }
  end

  def verify_date_fields(data, fields)
    fields.each { |field|
      if data.has_key?(field)
        formatted_date = "#{data[field][6..9]}-#{data[field][0..1]}-#{data[field][3..4]}"
        assert page.has_content?(formatted_date), @@system_test_utils.get_err_msg('Monitoree details', field, formatted_date)
      end
    }
  end

  def verify_age_fields(data, fields)
    fields.each { |field|
      if data.has_key?(field)
        age = @@system_test_utils.calculate_age(data[field])
        assert page.has_content?(age), @@system_test_utils.get_err_msg('Monitoree details', field, age)
      end
    }
  end

  def verify_checkbox_fields(data, fields)
    fields.each do |field, value|
      if data.has_key?(field.to_s)
        assert page.has_content?(value), @@system_test_utils.get_err_msg('Monitoree details', field, data[field.to_s])
      else
        assert page.has_no_content?(value), @@system_test_utils.get_err_msg('Monitoree details', field, data[field.to_s])
      end
    end
  end
end
