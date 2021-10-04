class UpdatePatientTableStringLengths < ActiveRecord::Migration[6.1]
  STRING_FIELDS = [
    # Identification
    :first_name,
    :last_name,
    :middle_name,
    :sex,
    :gender_identity,
    :sexual_orientation,
    :ethnicity,
    :nationality,
    :primary_language,
    :secondary_language,
    :user_defined_id_statelocal,
    :user_defined_id_cdc,
    :user_defined_id_nndss,

    # Address
    :address_line_1,
    :address_line_2,
    :address_city,
    :address_state,
    :address_zip,
    :address_county,
    :foreign_address_line_1,
    :foreign_address_line_2,
    :foreign_address_city,
    :foreign_address_country,
    :foreign_address_zip,
    :foreign_address_line_3,
    :foreign_address_state,
    :monitored_address_line_1,
    :monitored_address_line_2,
    :monitored_address_city,
    :monitored_address_state,
    :monitored_address_zip,
    :monitored_address_county,
    :foreign_monitored_address_line_1,
    :foreign_monitored_address_line_2,
    :foreign_monitored_address_city,
    :foreign_monitored_address_state,
    :foreign_monitored_address_zip,
    :foreign_monitored_address_county,

    # Contact
    :preferred_contact_method,
    :preferred_contact_time,
    :primary_telephone,
    :primary_telephone_type,
    :secondary_telephone,
    :secondary_telephone_type,
    :international_telephone,
    :email,

    # Arrival
    :port_of_origin,
    :flight_or_vessel_number,
    :flight_or_vessel_carrier,
    :port_of_entry_into_usa,
    :source_of_report,
    :source_of_report_specify,

    # Additional Planned Travel
    :additional_planned_travel_type,
    :additional_planned_travel_destination,
    :additional_planned_travel_destination_state,
    :additional_planned_travel_destination_country,
    :additional_planned_travel_port_of_departure,

    # Exposure
    :potential_exposure_location,
    :potential_exposure_country,
    :contact_of_known_case_id,
    :was_in_health_care_facility_with_known_cases_facility_name,
    :laboratory_personnel_facility_name,
    :healthcare_personnel_facility_name,
    :member_of_a_common_exposure_cohort_type,

    # Monitoring
    :exposure_risk_assessment,
    :monitoring_plan,
    :case_status,
    :public_health_action,
    :monitoring_reason,
    :follow_up_reason,

    # Other
    :legacy_primary_language,
    :legacy_secondary_language,
    :time_zone
  ]

  BINARY_FIELDS = %i[submission_token]

  OLD_LIMIT = 255
  NEW_LIMIT = 200

  def up
    ActiveRecord::Base.record_timestamps = false

    STRING_FIELDS.each { |field| change_column :patients, field, :string, limit: NEW_LIMIT }
    BINARY_FIELDS.each { |field| change_column :patients, field, :binary, limit: NEW_LIMIT }

    ActiveRecord::Base.record_timestamps = true
  end

  def down
    ActiveRecord::Base.record_timestamps = false

    STRING_FIELDS.each { |field| change_column :patients, field, :string, limit: OLD_LIMIT }
    BINARY_FIELDS.each { |field| change_column :patients, field, :binary, limit: OLD_LIMIT }

    ActiveRecord::Base.record_timestamps = true
  end
end
