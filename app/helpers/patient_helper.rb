# frozen_string_literal: true

# Helper methods for the patient model
module PatientHelper
  # This list contains all of the same states listed in app/javascript/components/data.js
  def state_names
    PATIENT_HELPER_FILES[:state_names]
  end

  # Offsets are DST
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

    name.delete(" \t\r\n").downcase
  end

  def normalize_and_get_state_name(name)
    state_names[normalize_name(name)] || nil
  end

  def time_zone_offset_for_state(name)
    # Grab state time zone information by name
    state = states_with_time_zone_data[normalize_name(name)]

    # Grab time zone offset
    offset = state.nil? ? -4 : state[:offset]

    # Adjust for DST (if observed)
    offset -= 1 if state && state[:observes_dst] && !Time.use_zone('Eastern Time (US & Canada)') { Time.now.dst? }

    # Format and return the offset
    (offset.negative? ? '' : '+') + format('%<offset>.2d', offset: offset) + ':00'
  end

  def time_zone_for_state(name)
    states_with_time_zone_data[normalize_name(name)][:zone_name]
  end

  def self.languages(language)
    languages = PATIENT_HELPER_FILES[:languages]
    languages[language&.downcase&.to_sym].present? ? languages[language&.downcase&.to_sym] : nil
  end

  # Calculated symptom onset date is based on latest symptomatic assessment.
  def calculated_symptom_onset(patient)
    patient.assessments.where(symptomatic: true).minimum(:created_at)&.to_date
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

  def self.info_fields
    %i[
      isolation
      first_name
      middle_name
      last_name
      secondary_telephone
      email
      date_of_birth
      address_line_1
      address_line_2
      address_city
      address_state
      address_zip
      monitored_address_line_1
      monitored_address_line_2
      monitored_address_city
      monitored_address_state
      monitored_address_zip
      primary_language
      interpretation_required
      white
      black_or_african_american
      american_indian_or_alaska_native
      asian
      native_hawaiian_or_other_pacific_islander
      ethnicity
      sex
      preferred_contact_method
      preferred_contact_time
    ]
  end
end
