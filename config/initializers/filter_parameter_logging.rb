# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
# The application just looks for the presence of these symbols. They are simply organized by table/model.

# Patient filters
Rails.application.config.filter_parameters += %i[password first_name middle_name last_name date_of_birth age sex white
                                                 black_or_african_american american_indian_or_alaska_native  asian
                                                 native_hawaiian_or_other_pacific_islander race_other race_unknown
                                                 race_refused_to_answer ethnicity nationality address_line_1 foreign_address_line_1
                                                 address_city address_state address_line_2 address_zip address_county monitored_address_line_1
                                                 monitored_address_city monitored_address_state monitored_address_line_2
                                                 monitored_address_zip monitored_address_country foreign_address_city
                                                 foreign_address_country foreign_address_line_2 foreign_address_zip
                                                 foreign_address_zip foreign_address_line_3 foreign_address_state
                                                 foreign_monitored_address_line_1 foreign_monitored_address_city
                                                 foreign_monitored_address_state foreign_monitored_address_line_2
                                                 foreign_monitored_address_zip foreign_monitored_address_county
                                                 primary_telephone secondary_telephone email port_of_origin
                                                 flight_or_vessel_number flight_or_vessel_carrier port_of_entry_into_usa
                                                 additional_planned_travel_type additional_planned_travel_destination
                                                 travel_related_notes additional_planned_travel_destination_state
                                                 additional_planned_travel_destination_country
                                                 additional_planned_travel_port_of_departure date_of_departure
                                                 date_of_arrival additional_planned_travel_start_date
                                                 additional_planned_travel_end_date
                                                 additional_planned_travel_related_notes last_date_of_exposure
                                                 potential_exposure_location potential_exposure_country
                                                 contact_of_known_case member_of_a_common_exposure_cohort
                                                 member_of_a_common_exposure_cohort_type exposure_risk_assessment
                                                 travel_to_affected_country_or_area laboratory_personnel
                                                 laboratory_personnel_facility_name healthcare_personnel
                                                 healthcare_personnel_facility_name crew_on_passenger_or_cargo_flight
                                                 was_in_health_care_facility_with_known_cases
                                                 was_in_health_care_facility_with_known_cases_facility_name
                                                 exposure_notes symptom_onset continuous_exposure latest_assessment_at
                                                 latest_fever_or_fever_reducer_at latest_positive_lab_at
                                                 negative_lab_count gender_identity sexual_orientation
                                                 extended_isolation isolation dob status user_defined_id_statelocal
                                                 user_defined_id_cdc user_defined_id_nndss]

# CloseContact filters
Rails.application.config.filter_parameters += %i[first_name last_name primary_telephone email notes]

# Symptom filters
Rails.application.config.filter_parameters += %i[bool_value float_value int_value value label name notes]

# Laboratory filters
Rails.application.config.filter_parameters += %i[lab_type specimen_collection report result]

# Assessment filters
Rails.application.config.filter_parameters += %i[symptomatic]

# History filters
Rails.application.config.filter_parameters += %i[comment]

# Vaccine filters
Rails.application.config.filter_parameters += %i[group_name product_name administration_date dose_number notes]
