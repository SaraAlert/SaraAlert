class UpdatePatientTableStringLengths < ActiveRecord::Migration[6.1]
  def up
    # Identification
    change_column :patients, :first_name, :string, limit: 128
    change_column :patients, :last_name, :string, limit: 128
    change_column :patients, :middle_name, :string, limit: 128
    change_column :patients, :sex, :string, limit: 16
    change_column :patients, :gender_identity, :string, limit: 128
    change_column :patients, :sexual_orientation, :string, limit: 128
    change_column :patients, :ethnicity, :string, limit: 64
    change_column :patients, :nationality, :string, limit: 64
    change_column :patients, :primary_language, :string, limit: 64
    change_column :patients, :secondary_language, :string, limit: 64
    change_column :patients, :user_defined_id_statelocal, :string, limit: 128
    change_column :patients, :user_defined_id_cdc, :string, limit: 128
    change_column :patients, :user_defined_id_nndss, :string, limit: 128

    # Address
    change_column :patients, :address_line_1, :string, limit: 128
    change_column :patients, :address_line_2, :string, limit: 128
    change_column :patients, :address_city, :string, limit: 128
    change_column :patients, :address_state, :string, limit: 128
    change_column :patients, :address_zip, :string, limit: 128
    change_column :patients, :address_county, :string, limit: 128
    change_column :patients, :foreign_address_line_1, :string, limit: 128
    change_column :patients, :foreign_address_line_2, :string, limit: 128
    change_column :patients, :foreign_address_city, :string, limit: 128
    change_column :patients, :foreign_address_country, :string, limit: 128
    change_column :patients, :foreign_address_zip, :string, limit: 128
    change_column :patients, :foreign_address_line_3, :string, limit: 128
    change_column :patients, :foreign_address_state, :string, limit: 128
    change_column :patients, :monitored_address_line_1, :string, limit: 128
    change_column :patients, :monitored_address_line_2, :string, limit: 128
    change_column :patients, :monitored_address_city, :string, limit: 128
    change_column :patients, :monitored_address_state, :string, limit: 128
    change_column :patients, :monitored_address_zip, :string, limit: 128
    change_column :patients, :monitored_address_county, :string, limit: 128
    change_column :patients, :foreign_monitored_address_line_1, :string, limit: 128
    change_column :patients, :foreign_monitored_address_line_2, :string, limit: 128
    change_column :patients, :foreign_monitored_address_city, :string, limit: 128
    change_column :patients, :foreign_monitored_address_state, :string, limit: 128
    change_column :patients, :foreign_monitored_address_zip, :string, limit: 128
    change_column :patients, :foreign_monitored_address_county, :string, limit: 128

    # Contact
    change_column :patients, :preferred_contact_method, :string, limit: 32
    change_column :patients, :preferred_contact_time, :string, limit: 16
    change_column :patients, :primary_telephone, :string, limit: 16
    change_column :patients, :primary_telephone_type, :string, limit: 16
    change_column :patients, :secondary_telephone, :string, limit: 16
    change_column :patients, :secondary_telephone_type, :string, limit: 16
    change_column :patients, :international_telephone, :string, limit: 64
    change_column :patients, :email, :string, limit: 128

    # Arrival
    change_column :patients, :port_of_origin, :string, limit: 128
    change_column :patients, :flight_or_vessel_number, :string, limit: 64
    change_column :patients, :flight_or_vessel_carrier, :string, limit: 64
    change_column :patients, :port_of_entry_into_usa, :string, limit: 128
    change_column :patients, :source_of_report, :string, limit: 64
    change_column :patients, :source_of_report_specify, :string, limit: 128

    # Additional Planned Travel
    change_column :patients, :additional_planned_travel_type, :string, limit: 16
    change_column :patients, :additional_planned_travel_destination, :string, limit: 128
    change_column :patients, :additional_planned_travel_destination_state, :string, limit: 128
    change_column :patients, :additional_planned_travel_destination_country, :string, limit: 128
    change_column :patients, :additional_planned_travel_port_of_departure, :string, limit: 128

    # Exposure
    change_column :patients, :potential_exposure_location, :string, limit: 128
    change_column :patients, :potential_exposure_country, :string, limit: 128
    change_column :patients, :contact_of_known_case_id, :string, limit: 128
    change_column :patients, :was_in_health_care_facility_with_known_cases_facility_name, :string, limit: 128
    change_column :patients, :laboratory_personnel_facility_name, :string, limit: 128
    change_column :patients, :healthcare_personnel_facility_name, :string, limit: 128
    change_column :patients, :member_of_a_common_exposure_cohort_type, :string, limit: 128

    # Monitoring
    change_column :patients, :exposure_risk_assessment, :string, limit: 64
    change_column :patients, :monitoring_plan, :string, limit: 64
    change_column :patients, :case_status, :string, limit: 128
    change_column :patients, :public_health_action, :string, limit: 64
    change_column :patients, :monitoring_reason, :string, limit: 64
    change_column :patients, :follow_up_reason, :string, limit: 64

    # Other
    change_column :patients, :legacy_primary_language, :string, limit: 64
    change_column :patients, :legacy_secondary_language, :string, limit: 64
    change_column :patients, :time_zone, :string, limit: 64
    change_column :patients, :submission_token, :binary, limit: 64
  end

  def down
    # Identification
    change_column :patients, :first_name, :string
    change_column :patients, :last_name, :string
    change_column :patients, :middle_name, :string
    change_column :patients, :sex, :string
    change_column :patients, :gender_identity, :string
    change_column :patients, :sexual_orientation, :string
    change_column :patients, :ethnicity, :string
    change_column :patients, :nationality, :string
    change_column :patients, :primary_language, :string
    change_column :patients, :secondary_language, :string
    change_column :patients, :user_defined_id_statelocal, :string
    change_column :patients, :user_defined_id_cdc, :string
    change_column :patients, :user_defined_id_nndss, :string

    # Address
    change_column :patients, :address_line_1, :string
    change_column :patients, :address_line_2, :string
    change_column :patients, :address_city, :string
    change_column :patients, :address_state, :string
    change_column :patients, :address_zip, :string
    change_column :patients, :address_county, :string
    change_column :patients, :foreign_address_line_1, :string
    change_column :patients, :foreign_address_line_2, :string
    change_column :patients, :foreign_address_city, :string
    change_column :patients, :foreign_address_country, :string
    change_column :patients, :foreign_address_zip, :string
    change_column :patients, :foreign_address_line_3, :string
    change_column :patients, :foreign_address_state, :string
    change_column :patients, :monitored_address_line_1, :string
    change_column :patients, :monitored_address_line_2, :string
    change_column :patients, :monitored_address_city, :string
    change_column :patients, :monitored_address_state, :string
    change_column :patients, :monitored_address_zip, :string
    change_column :patients, :monitored_address_county, :string
    change_column :patients, :foreign_monitored_address_line_1, :string
    change_column :patients, :foreign_monitored_address_line_2, :string
    change_column :patients, :foreign_monitored_address_city, :string
    change_column :patients, :foreign_monitored_address_state, :string
    change_column :patients, :foreign_monitored_address_zip, :string
    change_column :patients, :foreign_monitored_address_county, :string

    # Contact
    change_column :patients, :preferred_contact_method, :string
    change_column :patients, :preferred_contact_time, :string
    change_column :patients, :primary_telephone, :string
    change_column :patients, :primary_telephone_type, :string
    change_column :patients, :secondary_telephone, :string
    change_column :patients, :secondary_telephone_type, :string
    change_column :patients, :international_telephone, :string
    change_column :patients, :email, :string

    # Arrival
    change_column :patients, :port_of_origin, :string
    change_column :patients, :flight_or_vessel_number, :string
    change_column :patients, :flight_or_vessel_carrier, :string
    change_column :patients, :port_of_entry_into_usa, :string
    change_column :patients, :source_of_report, :string
    change_column :patients, :source_of_report_specify, :string

    # Additional Planned Travel
    change_column :patients, :additional_planned_travel_type, :string
    change_column :patients, :additional_planned_travel_destination, :string
    change_column :patients, :additional_planned_travel_destination_state, :string
    change_column :patients, :additional_planned_travel_destination_country, :string
    change_column :patients, :additional_planned_travel_port_of_departure, :string

    # Exposure
    change_column :patients, :potential_exposure_location, :string
    change_column :patients, :potential_exposure_country, :string
    change_column :patients, :contact_of_known_case_id, :string
    change_column :patients, :was_in_health_care_facility_with_known_cases_facility_name, :string
    change_column :patients, :laboratory_personnel_facility_name, :string
    change_column :patients, :healthcare_personnel_facility_name, :string
    change_column :patients, :member_of_a_common_exposure_cohort_type, :string

    # Monitoring
    change_column :patients, :exposure_risk_assessment, :string
    change_column :patients, :monitoring_plan, :string
    change_column :patients, :case_status, :string
    change_column :patients, :public_health_action, :string
    change_column :patients, :monitoring_reason, :string
    change_column :patients, :follow_up_reason, :string

    # Other
    change_column :patients, :legacy_primary_language, :string
    change_column :patients, :legacy_secondary_language, :string
    change_column :patients, :time_zone, :string
    change_column :patients, :submission_token, :binary, limit: 255
  end
end
