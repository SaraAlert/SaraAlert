# frozen_string_literal: true

# Helper methods for the patient model
module PatientHelper # rubocop:todo Metrics/ModuleLength
  # This list contains all of the same states listed in app/javascript/components/data.js
  def state_names
    PATIENT_HELPER_FILES[:state_names]
  end

  def states_with_time_zone_data
    PATIENT_HELPER_FILES[:states_with_time_zone_data]
  end

  def normalize_state_names(pat)
    pat.monitored_address_state = normalize_and_get_state_name(pat.monitored_address_state) || pat.monitored_address_state
    pat.address_state = normalize_and_get_state_name(pat.address_state) || pat.address_state
    adpt = pat.additional_planned_travel_destination_state
    pat.additional_planned_travel_destination_state = normalize_and_get_state_name(adpt) || adpt
  end

  def normalize_name(name)
    return nil if name.nil?

    name&.to_s&.delete(" \t\r\n")&.downcase
  end

  def normalize_and_get_state_name(name)
    state_names[normalize_name(name)] || nil
  end

  def time_zone_offset_for_state(name)
    # Call TimeZone#now to create a TimeWithZone object that will contextualize
    # the time to the current truth
    ActiveSupport::TimeZone[time_zone_for_state(name)].now.formatted_offset
  end

  def time_zone_for_state(name)
    states_with_time_zone_data[normalize_name(name)][:zone_name]
  end

  # Calculated symptom onset date is based on latest symptomatic assessment.
  def calculated_symptom_onset(patient)
    symptom_onset_ts = patient.assessments.where(symptomatic: true).minimum(:created_at)
    return if symptom_onset_ts.nil?

    tz = Time.find_zone(patient.time_zone) || Time.find_zone('America/New_York')
    tz.utc_to_local(symptom_onset_ts).to_date
  end

  def dashboard_crumb_title(dashboard)
    dashboard.nil? ? 'Return To Dashboard' : "Return to #{dashboard.titleize} Dashboard"
  end

  def self.monitoring_fields
    %i[
      monitoring
      monitoring_reason
      monitoring_plan
      exposure_risk_assessment
      public_health_action
      isolation
      pause_notifications
      symptom_onset
      case_status
      assigned_user
      last_date_of_exposure
      continuous_exposure
      user_defined_symptom_onset
      extended_isolation
      jurisdiction_id
    ]
  end

  # Parameters allowed for saving to database
  def allowed_params
    params.require(:patient).permit(
      :user_defined_id_statelocal,
      :user_defined_id_cdc,
      :user_defined_id_nndss,
      :first_name,
      :middle_name,
      :last_name,
      :date_of_birth,
      :age,
      :sex,
      :white,
      :black_or_african_american,
      :american_indian_or_alaska_native,
      :asian,
      :native_hawaiian_or_other_pacific_islander,
      :race_other,
      :race_unknown,
      :race_refused_to_answer,
      :ethnicity,
      :primary_language,
      :secondary_language,
      :interpretation_required,
      :nationality,
      :address_line_1,
      :foreign_address_line_1,
      :address_city,
      :address_state,
      :address_line_2,
      :address_zip,
      :address_county,
      :monitored_address_line_1,
      :monitored_address_city,
      :monitored_address_state,
      :monitored_address_line_2,
      :monitored_address_zip,
      :monitored_address_county,
      :foreign_address_city,
      :foreign_address_country,
      :foreign_address_line_2,
      :foreign_address_zip,
      :foreign_address_line_3,
      :foreign_address_state,
      :foreign_monitored_address_line_1,
      :foreign_monitored_address_city,
      :foreign_monitored_address_state,
      :foreign_monitored_address_line_2,
      :foreign_monitored_address_zip,
      :foreign_monitored_address_county,
      :contact_type,
      :contact_name,
      :primary_telephone,
      :primary_telephone_type,
      :secondary_telephone,
      :secondary_telephone_type,
      :international_telephone,
      :email,
      :preferred_contact_method,
      :preferred_contact_time,
      :alternate_contact_type,
      :alternate_contact_name,
      :alternate_primary_telephone,
      :alternate_primary_telephone_type,
      :alternate_secondary_telephone,
      :alternate_secondary_telephone_type,
      :alternate_international_telephone,
      :alternate_email,
      :alternate_preferred_contact_method,
      :alternate_preferred_contact_time,
      :port_of_origin,
      :source_of_report,
      :source_of_report_specify,
      :flight_or_vessel_number,
      :flight_or_vessel_carrier,
      :port_of_entry_into_usa,
      :travel_related_notes,
      :additional_planned_travel_type,
      :additional_planned_travel_destination,
      :additional_planned_travel_destination_state,
      :additional_planned_travel_destination_country,
      :additional_planned_travel_port_of_departure,
      :date_of_departure,
      :date_of_arrival,
      :additional_planned_travel_start_date,
      :additional_planned_travel_end_date,
      :additional_planned_travel_related_notes,
      :last_date_of_exposure,
      :potential_exposure_location,
      :potential_exposure_country,
      :contact_of_known_case,
      :contact_of_known_case_id,
      :travel_to_affected_country_or_area,
      :was_in_health_care_facility_with_known_cases,
      :was_in_health_care_facility_with_known_cases_facility_name,
      :laboratory_personnel,
      :laboratory_personnel_facility_name,
      :healthcare_personnel,
      :healthcare_personnel_facility_name,
      :exposure_notes,
      :crew_on_passenger_or_cargo_flight,
      :monitoring_plan,
      :exposure_risk_assessment,
      :isolation,
      :jurisdiction_id,
      :assigned_user,
      :symptom_onset,
      :extended_isolation,
      :case_status,
      :continuous_exposure,
      :gender_identity,
      :sexual_orientation,
      :user_defined_symptom_onset,
      :follow_up_reason,
      :follow_up_note,
      laboratories_attributes: %i[
        lab_type
        specimen_collection
        report
        result
      ],
      vaccines_attributes: %i[
        group_name
        product_name
        administration_date
        dose_number
        notes
      ],
      common_exposure_cohorts_attributes: %i[
        cohort_type
        cohort_name
        cohort_location
      ]
    )
  end

  # Fields that should be copied over from parent to group member for easier form completion
  def group_member_subset
    %i[
      address_line_1
      address_city
      address_state
      address_line_2
      address_zip
      address_county
      monitored_address_line_1
      monitored_address_city
      monitored_address_state
      monitored_address_line_2
      monitored_address_zip
      monitored_address_county
      foreign_address_line_1
      foreign_address_city
      foreign_address_country
      foreign_address_line_2
      foreign_address_zip
      foreign_address_line_3
      foreign_address_state
      foreign_monitored_address_line_1
      foreign_monitored_address_city
      foreign_monitored_address_state
      foreign_monitored_address_line_2
      foreign_monitored_address_zip
      foreign_monitored_address_county
      contact_name
      primary_telephone
      primary_telephone_type
      secondary_telephone
      secondary_telephone_type
      international_telephone
      email
      preferred_contact_method
      preferred_contact_time
      port_of_origin
      source_of_report
      source_of_report_specify
      flight_or_vessel_number
      flight_or_vessel_carrier
      port_of_entry_into_usa
      travel_related_notes
      additional_planned_travel_type
      additional_planned_travel_destination
      additional_planned_travel_destination_state
      additional_planned_travel_destination_country
      additional_planned_travel_port_of_departure
      date_of_departure
      date_of_arrival
      additional_planned_travel_start_date
      additional_planned_travel_end_date
      additional_planned_travel_related_notes
      last_date_of_exposure
      potential_exposure_location
      potential_exposure_country
      contact_of_known_case
      contact_of_known_case_id
      travel_to_affected_country_or_area
      was_in_health_care_facility_with_known_cases
      was_in_health_care_facility_with_known_cases_facility_name
      laboratory_personnel
      laboratory_personnel_facility_name
      healthcare_personnel
      healthcare_personnel_facility_name
      exposure_notes
      crew_on_passenger_or_cargo_flight
      isolation
      jurisdiction_id
      assigned_user
      continuous_exposure
    ]
  end
end
