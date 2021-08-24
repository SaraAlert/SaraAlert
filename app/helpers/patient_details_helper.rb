# frozen_string_literal: true

# Helper methods for the linelist and full history details
module PatientDetailsHelper # rubocop:todo Metrics/ModuleLength
  # If preferred contact time is X,
  # then valid contact hours in patient's local timezone are Y.
  # 'Morning'   => 0800 - 1200
  # 'Afternoon' => 1200 - 1600
  # 'Evening'   => 1600 - 1900
  #  default    => 1200 - 1600
  MORNING_CONTACT_WINDOW = (8..12).freeze
  AFTERNOON_CONTACT_WINDOW = (12..16).freeze
  EVENING_CONTACT_WINDOW = (16..19).freeze
  UNSPECIFIED_CONTACT_WINDOW = (12..16).freeze
  CUSTOM_CONTACT_OPTIONS = (0..23).to_a.map(&:to_s).freeze

  # Current patient status
  def status
    return :purged if purged
    return :closed unless monitoring

    unless isolation
      return :exposure_under_investigation if public_health_action != 'None'
      return :exposure_symptomatic unless symptom_onset.nil?
      return :exposure_asymptomatic if (!latest_assessment_at.nil? && latest_assessment_at >= ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago) ||
                                       (!created_at.nil? && created_at >= ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)

      return :exposure_non_reporting
    end

    return :isolation_asymp_non_test_based if !latest_assessment_at.nil? && !first_positive_lab_at.nil? && first_positive_lab_at < 10.days.ago &&
                                              symptom_onset.nil? && (!extended_isolation || extended_isolation < Date.today)
    return :isolation_symp_non_test_based if (latest_fever_or_fever_reducer_at.nil? || latest_fever_or_fever_reducer_at < 24.hours.ago) &&
                                             !symptom_onset.nil? && symptom_onset <= 10.days.ago && (!extended_isolation || extended_isolation < Date.today)
    return :isolation_test_based if !latest_assessment_at.nil? && (latest_fever_or_fever_reducer_at.nil? || latest_fever_or_fever_reducer_at < 24.hours.ago) &&
                                    negative_lab_count >= 2 && (!extended_isolation || extended_isolation < Date.today)
    return :isolation_reporting if (!latest_assessment_at.nil? && latest_assessment_at >= ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago) ||
                                   (!created_at.nil? && created_at >= ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)

    :isolation_non_reporting
  end

  # Current patient status as a string
  def status_as_string
    status&.to_s&.humanize&.downcase&.sub('exposure ', '')&.sub('isolation ', '')
  end

  # Information about this subject (that is useful in a linelist)
  def linelist
    {
      end_of_monitoring: (continuous_exposure ? 'Continuous Exposure' : end_of_monitoring) || ''
    }
  end

  # Information about this subject (that is useful in a linelist) (used by system tests export verifier)
  def linelist_for_export
    {
      id: id,
      name: first_name.present? || last_name.present? ? "#{last_name}#{first_name.blank? ? '' : ', ' + first_name}" : 'NAME NOT PROVIDED',
      jurisdiction_name: jurisdiction&.name || '',
      assigned_user: assigned_user || '',
      user_defined_id_statelocal: user_defined_id_statelocal || '',
      sex: sex || '',
      date_of_birth: date_of_birth&.strftime('%F') || '',
      end_of_monitoring: (continuous_exposure ? 'Continuous Exposure' : end_of_monitoring) || '',
      exposure_risk_assessment: exposure_risk_assessment || '',
      monitoring_plan: monitoring_plan || '',
      transferred_from: latest_transfer&.from_path || '',
      transferred_to: latest_transfer&.to_path || '',
      latest_assessment_at: latest_assessment_at || '',
      latest_transfer_at: latest_transfer_at || '',
      monitoring_reason: monitoring_reason || '',
      public_health_action: public_health_action || '',
      status: status&.to_s&.humanize&.downcase&.sub('exposure ', '')&.sub('isolation ', '') || '',
      closed_at: closed_at || '',
      expected_purge_ts: expected_purge_date_exp || '',
      symptom_onset: symptom_onset&.strftime('%F') || '',
      extended_isolation: extended_isolation || '',
      responder_id: responder_id || '',
      workflow: isolation ? 'Isolation' : 'Exposure',
      first_positive_lab_at: first_positive_lab_at || '',
      follow_up_reason: follow_up_reason || '',
      follow_up_note: follow_up_note || ''
    }
  end

  # All information about this subject (used by system tests export verifier)
  def full_history_details_for_export
    labs = Laboratory.where(patient_id: id).order(specimen_collection: :desc)
    vaccines = Vaccine.where(patient_id: id).order(administration_date: :desc)
    {
      first_name: first_name || '',
      middle_name: middle_name || '',
      last_name: last_name || '',
      date_of_birth: date_of_birth&.strftime('%F') || '',
      sex: sex || '',
      white: white || false,
      black_or_african_american: black_or_african_american || false,
      american_indian_or_alaska_native: american_indian_or_alaska_native || false,
      asian: asian || false,
      native_hawaiian_or_other_pacific_islander: native_hawaiian_or_other_pacific_islander || false,
      ethnicity: ethnicity || '',
      primary_language: primary_language || '',
      secondary_language: secondary_language || '',
      interpretation_required: interpretation_required || false,
      nationality: nationality || '',
      user_defined_id_statelocal: user_defined_id_statelocal || '',
      user_defined_id_cdc: user_defined_id_cdc || '',
      user_defined_id_nndss: user_defined_id_nndss || '',
      address_line_1: address_line_1 || '',
      address_city: address_city || '',
      address_state: address_state || '',
      address_line_2: address_line_2 || '',
      address_zip: address_zip || '',
      address_county: address_county || '',
      foreign_address_line_1: foreign_address_line_1 || '',
      foreign_address_city: foreign_address_city || '',
      foreign_address_country: foreign_address_country || '',
      foreign_address_line_2: foreign_address_line_2 || '',
      foreign_address_zip: foreign_address_zip || '',
      foreign_address_line_3: foreign_address_line_3 || '',
      foreign_address_state: foreign_address_state || '',
      monitored_address_line_1: monitored_address_line_1 || '',
      monitored_address_city: monitored_address_city || '',
      monitored_address_state: monitored_address_state || '',
      monitored_address_line_2: monitored_address_line_2 || '',
      monitored_address_zip: monitored_address_zip || '',
      monitored_address_county: monitored_address_county || '',
      foreign_monitored_address_line_1: foreign_monitored_address_line_1 || '',
      foreign_monitored_address_city: foreign_monitored_address_city || '',
      foreign_monitored_address_state: foreign_monitored_address_state || '',
      foreign_monitored_address_line_2: foreign_monitored_address_line_2 || '',
      foreign_monitored_address_zip: foreign_monitored_address_zip || '',
      foreign_monitored_address_county: foreign_monitored_address_county || '',
      preferred_contact_method: preferred_contact_method || '',
      primary_telephone: primary_telephone || '',
      primary_telephone_type: primary_telephone_type || '',
      secondary_telephone: secondary_telephone || '',
      secondary_telephone_type: secondary_telephone_type || '',
      preferred_contact_time: ValidationHelper::TIME_OPTIONS[preferred_contact_time&.to_sym] || '',
      email: email || '',
      port_of_origin: port_of_origin || '',
      date_of_departure: date_of_departure&.strftime('%F') || '',
      source_of_report: source_of_report || '',
      flight_or_vessel_number: flight_or_vessel_number || '',
      flight_or_vessel_carrier: flight_or_vessel_carrier || '',
      port_of_entry_into_usa: port_of_entry_into_usa || '',
      date_of_arrival: date_of_arrival&.strftime('%F') || '',
      travel_related_notes: travel_related_notes || '',
      additional_planned_travel_type: additional_planned_travel_type || '',
      additional_planned_travel_destination: additional_planned_travel_destination || '',
      additional_planned_travel_destination_state: additional_planned_travel_destination_state || '',
      additional_planned_travel_destination_country: additional_planned_travel_destination_country || '',
      additional_planned_travel_port_of_departure: additional_planned_travel_port_of_departure || '',
      additional_planned_travel_start_date: additional_planned_travel_start_date&.strftime('%F') || '',
      additional_planned_travel_end_date: additional_planned_travel_end_date&.strftime('%F') || '',
      additional_planned_travel_related_notes: additional_planned_travel_related_notes || '',
      last_date_of_exposure: last_date_of_exposure&.strftime('%F') || '',
      potential_exposure_location: potential_exposure_location || '',
      potential_exposure_country: potential_exposure_country || '',
      contact_of_known_case: contact_of_known_case || false,
      contact_of_known_case_id: contact_of_known_case_id || '',
      travel_to_affected_country_or_area: travel_to_affected_country_or_area || false,
      was_in_health_care_facility_with_known_cases: was_in_health_care_facility_with_known_cases || false,
      was_in_health_care_facility_with_known_cases_facility_name: was_in_health_care_facility_with_known_cases_facility_name || '',
      laboratory_personnel: laboratory_personnel || false,
      laboratory_personnel_facility_name: laboratory_personnel_facility_name || '',
      healthcare_personnel: healthcare_personnel || false,
      healthcare_personnel_facility_name: healthcare_personnel_facility_name || '',
      crew_on_passenger_or_cargo_flight: crew_on_passenger_or_cargo_flight || false,
      member_of_a_common_exposure_cohort: member_of_a_common_exposure_cohort || false,
      member_of_a_common_exposure_cohort_type: member_of_a_common_exposure_cohort_type || '',
      exposure_risk_assessment: exposure_risk_assessment || '',
      monitoring_plan: monitoring_plan || '',
      exposure_notes: exposure_notes || '',
      full_status: '',
      symptom_onset: symptom_onset&.strftime('%F') || '',
      case_status: case_status || '',
      lab_1_type: labs[0]&.lab_type || '',
      lab_1_specimen_collection: labs[0]&.specimen_collection&.strftime('%F') || '',
      lab_1_report: labs[0]&.report&.strftime('%F') || '',
      lab_1_result: labs[0]&.result || '',
      lab_2_type: labs[1]&.lab_type || '',
      lab_2_specimen_collection: labs[1]&.specimen_collection&.strftime('%F') || '',
      lab_2_report: labs[1]&.report&.strftime('%F') || '',
      lab_2_result: labs[1]&.result || '',
      jurisdiction_path: jurisdiction[:path] || '',
      assigned_user: assigned_user || '',
      gender_identity: gender_identity || '',
      sexual_orientation: sexual_orientation || '',
      race_other: race_other || false,
      race_unknown: race_unknown || false,
      race_refused_to_answer: race_refused_to_answer || false,
      vaccine_1_group_name: vaccines[0]&.group_name || '',
      vaccine_1_product_name: vaccines[0]&.product_name || '',
      vaccine_1_administration_date: vaccines[0]&.administration_date&.strftime('%F') || '',
      vaccine_1_dose_number: vaccines[0]&.dose_number || '',
      vaccine_1_notes: vaccines[0]&.notes,
      vaccine_2_group_name: vaccines[1]&.group_name || '',
      vaccine_2_product_name: vaccines[1]&.product_name || '',
      vaccine_2_administration_date: vaccines[1]&.administration_date&.strftime('%F') || '',
      vaccine_2_dose_number: vaccines[1]&.dose_number || '',
      vaccine_2_notes: vaccines[1]&.notes,
      follow_up_reason: follow_up_reason || '',
      follow_up_note: follow_up_note || ''
    }
  end

  # Getter used for testing custom exports.
  def custom_export_details_for_export
    additional_custom_export_details = {
      public_health_action: public_health_action || '',
      monitoring_status: monitoring ? 'Actively Monitoring' : 'Not Monitoring',
      workflow: isolation ? 'Isolation' : 'Exposure',
      age: calc_current_age || '',
      jurisdiction_name: jurisdiction[:name] || '',
      symptom_onset_defined_by: user_defined_symptom_onset ? 'User' : 'System',
      first_positive_lab_at: first_positive_lab_at || '',
      continuous_exposure: continuous_exposure || false,
      extended_isolation: extended_isolation || '',
      end_of_monitoring: end_of_monitoring || '',
      responder_id: responder_id || '',
      head_of_household: head_of_household || false,
      pause_notifications: pause_notifications || false,
      expected_purge_ts: expected_purge_date_exp || '',
      monitoring_reason: monitoring_reason || '',
      closed_at: closed_at || '',
      created_at: created_at || '',
      updated_at: updated_at || ''
    }

    full_history_details_for_export.merge(additional_custom_export_details)
  end
end
