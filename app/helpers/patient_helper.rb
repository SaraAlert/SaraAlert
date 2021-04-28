# frozen_string_literal: true

# Helper methods for the patient model
module PatientHelper
  # This list contains all of the same states listed in app/javascript/components/data.js
  def state_names
    PATIENT_HELPER_FILES[:state_names]
  end

  def states_with_time_zone_data
    PATIENT_HELPER_FILES[:states_with_time_zone_data]
  end

  def all_languages
    PATIENT_HELPER_FILES[:languages]
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

  # This function will attempt to match the input to a language in the system
  # PARAM: `lang` can be a three-letter iso-639-2t code, a two-letter iso-639-1 code, or the name (not case sensitive)
  # PARAM EXAMPLES: 'eng', 'en', 'English', 'ENGLISH' <-- All will map to 'eng'
  # RETURN VALUE: `nil` if unmatchable, else the three-letter iso code ('eng')
  def normalize_and_get_language_name(lang)
    return nil if lang.nil?

    # spa-PR is the only iso-code that involves case. it will not be properly matched if
    # we call downcase on the input
    lang = lang.casecmp('spa-pr')&.zero? ? 'spa-PR' : lang.to_s
    matched_language = nil
    matched_language = lang.to_sym if all_languages[lang.to_sym]
    return matched_language unless matched_language.nil?

    matched_language = all_languages.find { |_key, val| val[:display]&.casecmp(lang)&.zero? }
    return matched_language[0] unless matched_language.nil?

    matched_language = all_languages.find { |_key, val| val[:iso6391code]&.casecmp(lang)&.zero? }
    return matched_language[0] unless matched_language.nil?

    matched_language
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
end
