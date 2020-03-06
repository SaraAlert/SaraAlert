require "application_system_test_case"

require_relative "../system_test_utils"

class MonitoreeEnrollmentFormPopulator < ApplicationSystemTestCase

  @@system_test_utils = SystemTestUtils.new(nil)
  
  def populate_monitoree_info(monitoree)
    populate_identification(monitoree["identification"], true)
    populate_address(monitoree["address"], true)
    populate_contact_info(monitoree["contact_info"], true)
    populate_arrival_info(monitoree["arrival_info"], true)
    populate_additional_planned_travel(monitoree["additional_planned_travel"], true)
    populate_potential_exposure_info(monitoree["potential_exposure_info"], true)
  end

  def populate_monitoree_info_with_same_monitored_address_as_home(monitoree)
    populate_identification(monitoree["identification"], true)
    populate_address(monitoree["address"], false)
    click_on "Set to Home Address"
    assert_equal(monitoree["address"]["address_line_1"], find("#monitored_address_line_1")["value"])
    assert_equal(monitoree["address"]["address_city"], find("#monitored_address_city")["value"])
    assert_equal(monitoree["address"]["address_line_2"], find("#monitored_address_line_2")["value"])
    assert_equal(monitoree["address"]["address_state"], find("#monitored_address_state")["value"])
    assert_equal(monitoree["address"]["address_zip"], find("#monitored_address_zip")["value"])
    assert_equal(monitoree["address"]["address_county"], find("#monitored_address_county")["value"])
  end
  
  def populate_identification(identification, continue)
    populate_text_input(identification, "first_name")
    populate_text_input(identification, "middle_name")
    populate_text_input(identification, "last_name")
    populate_text_input(identification, "date_of_birth")
    populate_select_input(identification, "sex")
    populate_checkbox_input(identification, "white")
    populate_checkbox_input(identification, "black_or_african_american")
    populate_checkbox_input(identification, "american_indian_or_alaska_native")
    populate_checkbox_input(identification, "asian")
    populate_checkbox_input(identification, "native_hawaiian_or_other_pacific_islander")
    populate_select_input(identification, "ethnicity")
    populate_text_input(identification, "primary_language")
    populate_text_input(identification, "secondary_language")
    populate_checkbox_input(identification, "interpretation_required")
    populate_text_input(identification, "nationality")
    populate_text_input(identification, "user_defined_id_statelocal")
    populate_text_input(identification, "user_defined_id_cdc")
    populate_text_input(identification, "user_defined_id_nndss")
    @@system_test_utils.go_to_next_page if continue
  end

  def populate_address(address, continue)
    if address
      if address["address_line_1"]
        populate_text_input(address, "address_line_1")
        populate_text_input(address, "address_city")
        populate_select_input(address, "address_state")
        populate_text_input(address, "address_line_2")
        populate_text_input(address, "address_zip")
        populate_text_input(address, "address_county")
        populate_text_input(address, "monitored_address_line_1")
        populate_text_input(address, "monitored_address_line_2")
        populate_text_input(address, "monitored_address_city")
        populate_select_input(address, "monitored_address_state")
        populate_text_input(address, "monitored_address_zip")
        populate_text_input(address, "monitored_address_county")
      end
      if address["foreign_address_city"]
        click_on "Home Address Outside USA (Foreign)"
        populate_text_input(address, "foreign_address_line_1")
        populate_text_input(address, "foreign_address_city")
        populate_select_input(address, "foreign_address_country")
        populate_text_input(address, "foreign_address_line_2")
        populate_text_input(address, "foreign_address_zip")
        populate_text_input(address, "foreign_address_line_3")
        populate_text_input(address, "foreign_address_state")
        populate_text_input(address, "foreign_monitored_address_line_1")
        populate_text_input(address, "foreign_monitored_address_city")
        populate_select_input(address, "foreign_monitored_address_state")
        populate_text_input(address, "foreign_monitored_address_line_2")
        populate_text_input(address, "foreign_monitored_address_zip")
        populate_text_input(address, "foreign_monitored_address_county")
      end
    end
    @@system_test_utils.go_to_next_page if continue
  end

  def populate_contact_info(contact_info, continue)
    if contact_info
      populate_text_input(contact_info, "primary_telephone")
      populate_select_input(contact_info, "primary_telephone_type")
      populate_text_input(contact_info, "secondary_telephone")
      populate_select_input(contact_info, "secondary_telephone_type")
      populate_text_input(contact_info, "email")
      populate_text_input(contact_info, "confirm_email")
      populate_select_input(contact_info, "preferred_contact_method")
      populate_select_input(contact_info, "preferred_contact_time")
    end
    @@system_test_utils.go_to_next_page if continue
  end

  def populate_arrival_info(arrival_info, continue)
    if arrival_info
      populate_text_input(arrival_info, "port_of_origin")
      populate_text_input(arrival_info, "date_of_departure")
      populate_select_input(arrival_info, "source_of_report")
      populate_text_input(arrival_info, "flight_or_vessel_number")
      populate_text_input(arrival_info, "flight_or_vessel_carrier")
      populate_text_input(arrival_info, "port_of_entry_into_usa")
      populate_text_input(arrival_info, "date_of_arrival")
      populate_text_input(arrival_info, "travel_related_notes")
    end
    @@system_test_utils.go_to_next_page if continue
  end

  def populate_additional_planned_travel(additional_planned_travel, continue)
    if additional_planned_travel
      populate_select_input(additional_planned_travel, "additional_planned_travel_type")
      populate_text_input(additional_planned_travel, "additional_planned_travel_destination")
      populate_select_input(additional_planned_travel, "additional_planned_travel_destination_state")
      populate_select_input(additional_planned_travel, "additional_planned_travel_destination_country")
      populate_text_input(additional_planned_travel, "additional_planned_travel_port_of_departure")
      populate_text_input(additional_planned_travel, "additional_planned_travel_start_date")
      populate_text_input(additional_planned_travel, "additional_planned_travel_end_date")
      populate_text_input(additional_planned_travel, "additional_planned_travel_related_notes")
    end
    @@system_test_utils.go_to_next_page if continue
  end

  def populate_potential_exposure_info(potential_exposure_info, continue)
    if potential_exposure_info
      populate_text_input(potential_exposure_info, "last_date_of_exposure")
      populate_text_input(potential_exposure_info, "potential_exposure_location")
      populate_select_input(potential_exposure_info, "potential_exposure_country")
      populate_checkbox_input_with_custom_label(potential_exposure_info, "contact_of_known_case", "CLOSE CONTACT WITH A KNOWN CASE")
      populate_checkbox_input(potential_exposure_info, "travel_to_affected_country_or_area")
      populate_checkbox_input(potential_exposure_info, "was_in_health_care_facility_with_known_cases")
      populate_checkbox_input(potential_exposure_info, "laboratory_personnel")
      populate_checkbox_input(potential_exposure_info, "healthcare_personnel")
      populate_checkbox_input(potential_exposure_info, "crew_on_passenger_or_cargo_flight")
      populate_text_input(potential_exposure_info, "contact_of_known_case_id")
      populate_select_input(potential_exposure_info, "exposure_risk_assessment")
      populate_select_input(potential_exposure_info, "monitoring_plan")
      populate_text_input(potential_exposure_info, "exposure_notes")
    end
    @@system_test_utils.go_to_next_page if continue
  end

  def populate_text_input(data, field)
    fill_in field, with: data[field] if data[field]
  end

  def populate_select_input(data, field)
    select data[field], from: field if data[field]
  end

  def populate_checkbox_input(data, field)
    populate_checkbox_input_with_custom_label(data, field, field.upcase.gsub("_", " "))
  end

  def populate_checkbox_input_with_custom_label(data, field, label)
    find("label", text: label).click if data[field]
  end

end