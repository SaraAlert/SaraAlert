# frozen_string_literal: true

# Helper methods for the linelist and comprehensive details
module PatientDetailsHelper # rubocop:todo Metrics/ModuleLength
  def get_comprehensive_details(patients, patient_statuses)
    comprehensive_details = get_incomplete_comprehensive_details(patients)
    patients_jurisdiction_paths = get_jurisdiction_paths(patients)
    patients_labs = get_latest_labs(patients)
    patients.each do |patient|
      comprehensive_details[patient.id][:jurisdiction_path] = patients_jurisdiction_paths[patient.id]
      comprehensive_details[patient.id][:status] = patient_statuses[patient.id]
      next unless patients_labs.key?(patient.id)
      next unless patients_labs[patient.id].key?(:first)

      comprehensive_details[patient.id][:lab_1_type] = patients_labs[patient.id][:first][:lab_type]
      comprehensive_details[patient.id][:lab_1_specimen_collection] = patients_labs[patient.id][:first][:specimen_collection]&.strftime('%F')
      comprehensive_details[patient.id][:lab_1_report] = patients_labs[patient.id][:first][:report]&.strftime('%F')
      comprehensive_details[patient.id][:lab_1_result] = patients_labs[patient.id][:first][:result]
      next unless patients_labs[patient.id].key?(:second)

      comprehensive_details[patient.id][:lab_2_type] = patients_labs[patient.id][:second][:lab_type]
      comprehensive_details[patient.id][:lab_2_specimen_collection] = patients_labs[patient.id][:second][:specimen_collection]&.strftime('%F')
      comprehensive_details[patient.id][:lab_2_report] = patients_labs[patient.id][:second][:report]&.strftime('%F')
      comprehensive_details[patient.id][:lab_2_result] = patients_labs[patient.id][:second][:result]
    end
    comprehensive_details
  end

  def get_linelists(patients, patient_statuses)
    linelists = get_incomplete_linelists(patients)
    patients_jurisdiction_names = get_jurisdiction_names(patients)
    patients_assessments = get_latest_assessments(patients)
    patients_end_of_monitorings = get_end_of_monitorings(patients)
    patients_transfers = get_latest_transfers(patients)
    patients.each do |patient|
      linelists[patient.id][:jurisdiction] = patients_jurisdiction_names[patient.id]
      linelists[patient.id][:status] = patient_statuses[patient.id]&.gsub('exposure ', '')&.gsub('isolation ', '')
      linelists[patient.id][:latest_report] = patients_assessments[patient.id]&.rfc2822
      linelists[patient.id][:end_of_monitoring] = patients_end_of_monitorings[patient.id]
      next unless patients_transfers[patient.id]

      linelists[patient.id][:transferred_at] = patients_transfers[patient.id][:transferred_at]&.rfc2822
      linelists[patient.id][:transferred_from] = patients_transfers[patient.id][:transferred_from]
      linelists[patient.id][:transferred_to] = patients_transfers[patient.id][:transferred_to]
    end
    linelists
  end

  def get_patient_statuses(patients)
    statuses = {
      closed: patients.monitoring_closed.pluck(:id),
      purged: patients.purged.pluck(:id),
      exposure_symptomatic: patients.exposure_symptomatic.pluck(:id),
      exposure_non_reporting: patients.exposure_non_reporting.pluck(:id),
      exposure_asymptomatic: patients.exposure_asymptomatic.pluck(:id),
      exposure_under_investigation: patients.exposure_under_investigation.pluck(:id),
      isolation_asymp_non_test_based: patients.isolation_asymp_non_test_based.pluck(:id),
      isolation_symp_non_test_based: patients.isolation_symp_non_test_based.pluck(:id),
      isolation_test_based: patients.isolation_test_based.pluck(:id),
      isolation_non_reporting: patients.isolation_non_reporting.pluck(:id),
      isolation_reporting: patients.isolation_reporting.pluck(:id)
    }
    patient_statuses = {}
    statuses.each do |status, patient_ids|
      patient_ids.each do |patient_id|
        patient_statuses[patient_id] = status&.to_s&.humanize&.downcase
      end
    end
    patient_statuses
  end

  def get_exposure_statuses(patients)
    patients = Patient.where(id: patients.pluck(:id))
    statuses = {
      closed: patients.monitoring_closed.pluck(:id),
      purged: patients.purged.pluck(:id),
      symptomatic: patients.exposure_symptomatic.pluck(:id),
      non_reporting: patients.exposure_non_reporting.pluck(:id),
      asymptomatic: patients.exposure_asymptomatic.pluck(:id),
      under_investigation: patients.exposure_under_investigation.pluck(:id)
    }
    patient_statuses = {}
    statuses.each do |status, patient_ids|
      patient_ids.each do |patient_id|
        patient_statuses[patient_id] = status&.to_s&.humanize&.downcase
      end
    end
    patient_statuses
  end

  def get_isolation_statuses(patients)
    patients = Patient.where(id: patients.pluck(:id))
    statuses = {
      closed: patients.monitoring_closed.pluck(:id),
      purged: patients.purged.pluck(:id),
      asymp_non_test_based: patients.isolation_asymp_non_test_based.pluck(:id),
      symp_non_test_based: patients.isolation_symp_non_test_based.pluck(:id),
      test_based: patients.isolation_test_based.pluck(:id),
      non_reporting: patients.isolation_non_reporting.pluck(:id),
      reporting: patients.isolation_reporting.pluck(:id)
    }
    patient_statuses = {}
    statuses.each do |status, patient_ids|
      patient_ids.each do |patient_id|
        patient_statuses[patient_id] = status&.to_s&.humanize&.downcase
      end
    end
    patient_statuses
  end

  def get_latest_assessments(patients)
    Assessment.where(patient_id: patients.pluck(:id)).group(:patient_id).maximum(:created_at)
  end

  def get_latest_transfers(patients)
    latest_transfers = Transfer.where(patient_id: patients.pluck(:id)).group(:patient_id).maximum(:created_at)
    transfers = Transfer.where(patient_id: latest_transfers.keys, created_at: latest_transfers.values)
    jurisdictions = Jurisdiction.find(transfers.pluck(:from_jurisdiction_id, :to_jurisdiction_id).flatten.uniq)
    jurisdiction_paths = Hash[jurisdictions.pluck(:id, :path).map { |id, path| [id, path] }]
    Hash[transfers.pluck(:patient_id, :created_at, :from_jurisdiction_id, :to_jurisdiction_id)
                  .map do |patient_id, created_at, from_jurisdiction_id, to_jurisdiction_id|
                    [patient_id, {
                      transferred_at: created_at,
                      transferred_from: jurisdiction_paths[from_jurisdiction_id],
                      transferred_to: jurisdiction_paths[to_jurisdiction_id]
                    }]
                  end
        ]
  end

  def get_end_of_monitorings(patients)
    end_of_monitorings = {}
    patients.each do |patient|
      start = patient[:last_date_of_exposure].present? ? patient[:last_date_of_exposure] : patient[:created_at]
      end_of_monitorings[patient.id] = (start + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s
    end
    end_of_monitorings
  end

  def get_latest_labs(patients)
    latest_labs = Hash[patients.pluck(:id).map { |id| [id, {}] }]
    Laboratory.where(patient_id: patients.pluck(:id)).order(report: :desc).each do |lab|
      if !latest_labs[lab.patient_id].key?(:first)
        latest_labs[lab.patient_id][:first] = {
          lab_type: lab[:lab_type],
          specimen_collection: lab[:specimen_collection],
          report: lab[:report],
          result: lab[:result]
        }
      elsif !latest_labs[lab.patient_id].key?(:second)
        latest_labs[lab.patient_id][:second] = {
          lab_type: lab[:lab_type],
          specimen_collection: lab[:specimen_collection],
          report: lab[:report],
          result: lab[:result]
        }
      end
    end
    latest_labs
  end

  def get_jurisdiction_paths(patients)
    jurisdiction_paths = Hash[Jurisdiction.find(patients.pluck(:jurisdiction_id).uniq).pluck(:id, :path).map { |id, path| [id, path] }]
    patients_jurisdiction_paths = {}
    patients.each do |patient|
      patients_jurisdiction_paths[patient.id] = jurisdiction_paths[patient.jurisdiction_id]
    end
    patients_jurisdiction_paths
  end

  def get_jurisdiction_names(patients)
    jurisdiction_names = Hash[Jurisdiction.find(patients.pluck(:jurisdiction_id).uniq).pluck(:id, :name).map { |id, name| [id, name] }]
    patients_jurisdiction_names = {}
    patients.each do |patient|
      patients_jurisdiction_names[patient.id] = jurisdiction_names[patient.jurisdiction_id]
    end
    patients_jurisdiction_names
  end

  def get_incomplete_linelists(patients)
    linelists = {}
    patients.each do |patient|
      linelists[patient.id] = {
        id: patient[:id],
        name: "#{patient[:last_name]}#{patient[:first_name].blank? ? '' : ', ' + patient[:first_name]}",
        jurisdiction: '',
        assigned_user: patient[:assigned_user] || '',
        state_local_id: patient[:user_defined_id_statelocal] || '',
        sex: patient[:sex] || '',
        dob: patient[:date_of_birth]&.strftime('%F') || '',
        end_of_monitoring: '',
        risk_level: patient[:exposure_risk_assessment] || '',
        monitoring_plan: patient[:monitoring_plan] || '',
        latest_report: '',
        transferred: '',
        reason_for_closure: patient[:monitoring_reason] || '',
        public_health_action: patient[:public_health_action] || '',
        status: '',
        closed_at: patient[:closed_at]&.rfc2822 || '',
        transferred_from: '',
        transferred_to: '',
        expected_purge_date: patient[:updated_at].nil? ? '' : ((patient[:updated_at] + ADMIN_OPTIONS['purgeable_after'].minutes)&.rfc2822 || '')
      }
    end
    linelists
  end

  def get_incomplete_comprehensive_details(patients) # rubocop:todo Metrics/MethodLength
    comprehensive_details = {}
    patients.each do |patient|
      comprehensive_details[patient.id] = {
        first_name: patient[:first_name] || '',
        middle_name: patient[:middle_name] || '',
        last_name: patient[:last_name] || '',
        date_of_birth: patient[:date_of_birth]&.strftime('%F') || '',
        sex: patient[:sex] || '',
        white: patient[:white] || false,
        black_or_african_american: patient[:black_or_african_american] || false,
        american_indian_or_alaska_native: patient[:american_indian_or_alaska_native] || false,
        asian: patient[:asian] || false,
        native_hawaiian_or_other_pacific_islander: patient[:native_hawaiian_or_other_pacific_islander] || false,
        ethnicity: patient[:ethnicity] || '',
        primary_language: patient[:primary_language] || '',
        secondary_language: patient[:secondary_language] || '',
        interpretation_required: patient[:interpretation_required] || false,
        nationality: patient[:nationality] || '',
        user_defined_id_statelocal: patient[:user_defined_id_statelocal] || '',
        user_defined_id_cdc: patient[:user_defined_id_cdc] || '',
        user_defined_id_nndss: patient[:user_defined_id_nndss] || '',
        address_line_1: patient[:address_line_1] || '',
        address_city: patient[:address_city] || '',
        address_state: patient[:address_state] || '',
        address_line_2: patient[:address_line_2] || '',
        address_zip: patient[:address_zip] || '',
        address_county: patient[:address_county] || '',
        foreign_address_line_1: patient[:foreign_address_line_1] || '',
        foreign_address_city: patient[:foreign_address_city] || '',
        foreign_address_country: patient[:foreign_address_country] || '',
        foreign_address_line_2: patient[:foreign_address_line_2] || '',
        foreign_address_zip: patient[:foreign_address_zip] || '',
        foreign_address_line_3: patient[:foreign_address_line_3] || '',
        foreign_address_state: patient[:foreign_address_state] || '',
        monitored_address_line_1: patient[:monitored_address_line_1] || '',
        monitored_address_city: patient[:monitored_address_city] || '',
        monitored_address_state: patient[:monitored_address_state] || '',
        monitored_address_line_2: patient[:monitored_address_line_2] || '',
        monitored_address_zip: patient[:monitored_address_zip] || '',
        monitored_address_county: patient[:monitored_address_county] || '',
        foreign_monitored_address_line_1: patient[:foreign_monitored_address_line_1] || '',
        foreign_monitored_address_city: patient[:foreign_monitored_address_city] || '',
        foreign_monitored_address_state: patient[:foreign_monitored_address_state] || '',
        foreign_monitored_address_line_2: patient[:foreign_monitored_address_line_2] || '',
        foreign_monitored_address_zip: patient[:foreign_monitored_address_zip] || '',
        foreign_monitored_address_county: patient[:foreign_monitored_address_county] || '',
        preferred_contact_method: patient[:preferred_contact_method] || '',
        primary_telephone: patient[:primary_telephone] || '',
        primary_telephone_type: patient[:primary_telephone_type] || '',
        secondary_telephone: patient[:secondary_telephone] || '',
        secondary_telephone_type: patient[:secondary_telephone_type] || '',
        preferred_contact_time: patient[:preferred_contact_time] || '',
        email: patient[:email] || '',
        port_of_origin: patient[:port_of_origin] || '',
        date_of_departure: patient[:date_of_departure]&.strftime('%F') || '',
        source_of_report: patient[:source_of_report] || '',
        flight_or_vessel_number: patient[:flight_or_vessel_number] || '',
        flight_or_vessel_carrier: patient[:flight_or_vessel_carrier] || '',
        port_of_entry_into_usa: patient[:port_of_entry_into_usa] || '',
        date_of_arrival: patient[:date_of_arrival]&.strftime('%F') || '',
        travel_related_notes: patient[:travel_related_notes] || '',
        additional_planned_travel_type: patient[:additional_planned_travel_type] || '',
        additional_planned_travel_destination: patient[:additional_planned_travel_destination] || '',
        additional_planned_travel_destination_state: patient[:additional_planned_travel_destination_state] || '',
        additional_planned_travel_destination_country: patient[:additional_planned_travel_destination_country] || '',
        additional_planned_travel_port_of_departure: patient[:additional_planned_travel_port_of_departure] || '',
        additional_planned_travel_start_date: patient[:additional_planned_travel_start_date]&.strftime('%F') || '',
        additional_planned_travel_end_date: patient[:additional_planned_travel_end_date]&.strftime('%F') || '',
        additional_planned_travel_related_notes: patient[:additional_planned_travel_related_notes] || '',
        last_date_of_exposure: patient[:last_date_of_exposure]&.strftime('%F') || '',
        potential_exposure_location: patient[:potential_exposure_location] || '',
        potential_exposure_country: patient[:potential_exposure_country] || '',
        contact_of_known_case: patient[:contact_of_known_case] || '',
        contact_of_known_case_id: patient[:contact_of_known_case_id] || '',
        travel_to_affected_country_or_area: patient[:travel_to_affected_country_or_area] || false,
        was_in_health_care_facility_with_known_cases: patient[:was_in_health_care_facility_with_known_cases] || false,
        was_in_health_care_facility_with_known_cases_facility_name: patient[:was_in_health_care_facility_with_known_cases_facility_name] || '',
        laboratory_personnel: patient[:laboratory_personnel] || false,
        laboratory_personnel_facility_name: patient[:laboratory_personnel_facility_name] || '',
        healthcare_personnel: patient[:healthcare_personnel] || false,
        healthcare_personnel_facility_name: patient[:healthcare_personnel_facility_name] || '',
        crew_on_passenger_or_cargo_flight: patient[:crew_on_passenger_or_cargo_flight] || false,
        member_of_a_common_exposure_cohort: patient[:member_of_a_common_exposure_cohort] || false,
        member_of_a_common_exposure_cohort_type: patient[:member_of_a_common_exposure_cohort_type] || '',
        exposure_risk_assessment: patient[:exposure_risk_assessment] || '',
        monitoring_plan: patient[:monitoring_plan] || '',
        exposure_notes: patient[:exposure_notes] || '',
        status: '',
        symptom_onset: patient[:symptom_onset]&.strftime('%F') || '',
        case_status: patient[:case_status] || '',
        lab_1_type: '',
        lab_1_specimen_collection: '',
        lab_1_report: '',
        lab_1_result: '',
        lab_2_type: '',
        lab_2_specimen_collection: '',
        lab_2_report: '',
        lab_2_result: '',
        jurisdiction_path: '',
        assigned_user: patient[:assigned_user] || ''
      }
    end
    comprehensive_details
  end
end
