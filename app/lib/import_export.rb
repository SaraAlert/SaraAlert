# frozen_string_literal: true

# Helper methods for the import and export controllers
module ImportExport # rubocop:todo Metrics/ModuleLength
  LINELIST_HEADERS = ['Patient ID', 'Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level',
                      'Monitoring Plan', 'Latest Report', 'Transferred At', 'Reason For Closure', 'Latest Public Health Action', 'Status', 'Closed At',
                      'Transferred From', 'Transferred To', 'Expected Purge Date'].freeze

  COMPREHENSIVE_HEADERS = ['First Name', 'Middle Name', 'Last Name', 'Date of Birth', 'Sex at Birth', 'White', 'Black or African American',
                           'American Indian or Alaska Native', 'Asian', 'Native Hawaiian or Other Pacific Islander', 'Ethnicity', 'Primary Language',
                           'Secondary Language', 'Interpretation Required?', 'Nationality', 'Identifier (STATE/LOCAL)', 'Identifier (CDC)',
                           'Identifier (NNDSS)', 'Address Line 1', 'Address City', 'Address State', 'Address Line 2', 'Address Zip', 'Address County',
                           'Foreign Address Line 1', 'Foreign Address City', 'Foreign Address Country', 'Foreign Address Line 2', 'Foreign Address Zip',
                           'Foreign Address Line 3', 'Foreign Address State', 'Monitored Address Line 1', 'Monitored Address City', 'Monitored Address State',
                           'Monitored Address Line 2', 'Monitored Address Zip', 'Monitored Address County', 'Foreign Monitored Address Line 1',
                           'Foreign Monitored Address City', 'Foreign Monitored Address State', 'Foreign Monitored Address Line 2',
                           'Foreign Monitored Address Zip', 'Foreign Monitored Address County', 'Preferred Contact Method', 'Primary Telephone',
                           'Primary Telephone Type', 'Secondary Telephone', 'Secondary Telephone Type', 'Preferred Contact Time', 'Email', 'Port of Origin',
                           'Date of Departure', 'Source of Report', 'Flight or Vessel Number', 'Flight or Vessel Carrier', 'Port of Entry Into USA',
                           'Date of Arrival', 'Travel Related Notes', 'Additional Planned Travel Type', 'Additional Planned Travel Destination',
                           'Additional Planned Travel Destination State', 'Additional Planned Travel Destination Country',
                           'Additional Planned Travel Port of Departure', 'Additional Planned Travel Start Date', 'Additional Planned Travel End Date',
                           'Additional Planned Travel Related Notes', 'Last Date of Exposure', 'Potential Exposure Location', 'Potential Exposure Country',
                           'Contact of Known Case?', 'Contact of Known Case ID', 'Travel from Affected Country or Area?',
                           'Was in Health Care Facility With Known Cases?', 'Health Care Facility with Known Cases Name', 'Laboratory Personnel?',
                           'Laboratory Personnel Facility Name', 'Health Care Personnel?', 'Health Care Personnel Facility Name',
                           'Crew on Passenger or Cargo Flight?', 'Member of a Common Exposure Cohort?', 'Common Exposure Cohort Name',
                           'Exposure Risk Assessment', 'Monitoring Plan', 'Exposure Notes', 'Status', 'Symptom Onset Date', 'Case Status', 'Lab 1 Test Type',
                           'Lab 1 Specimen Collection Date', 'Lab 1 Report Date', 'Lab 1 Result', 'Lab 2 Test Type', 'Lab 2 Specimen Collection Date',
                           'Lab 2 Report Date', 'Lab 2 Result', 'Full Assigned Jurisdiction Path', 'Assigned User', 'Gender Identity',
                           'Sexual Orientation'].freeze

  MONITOREES_LIST_HEADERS = ['Patient ID'] + COMPREHENSIVE_HEADERS.freeze

  EPI_X_HEADERS = ['Local-ID', 'Flight No', 'Date of notice', 'MDH Assignee', 'DGMQ ID', 'CARE ID', 'CARE Cell Number', 'Language', 'Arrival Date and Time',
                   'Arrival City', 'Last Name', 'First Name', 'Date of Birth', 'Gender', 'Passport Country', 'Passport Number', 'Permanent Street Address',
                   'Permanent City', 'Permanent State or Country', 'Postal Code', 'Temporary Street Address 1', 'Temporary City 1', 'Temporary State 1',
                   'Temporary Postal Code 1', 'Temporary Street Address 2', 'Temporary City 2', 'Temporary State 2', 'Temporary Postal Code 2',
                   'Phone Number 1', 'Phone Number 2', 'Email 1', 'Email 2', 'Emergency Contact Name', 'Emergency Contact Telephone Number',
                   'Emergency Contact Email', 'Countries Visited with Widespread Transmission in Past 14 Days', 'Departure Date',
                   'DHS Observed Vomiting, Diarrhea or Bleeding', 'Temperature taken by DHS', 'Fever/Chills in the past 48 hours',
                   'Vomiting/Diarrhea in the past 48 hours', 'Lived in Same Household or Had Other Contact with a Person Sick with disease in Past 14 Days',
                   'Worked in Health Care Facility or Laboratory in Country with Widespread Transmission in Past 14 Days',
                   'Touched Body of Someone who Died in Country with Widespread Transmission in Past 14 Days',
                   'DHS Traveler Health Declaration Outcome: Released', 'DHS Traveler Health Declaration Outcome: Referred to Tertiary for Add\'l Assessment',
                   'Disposition of Travelers Referred for CDC Assessment: Released to Continue Travel',
                   'Disposition of Travelers Referred for CDC Assessment: Coordinated Disposition with State Health Dept.',
                   'Disposition of Travelers Referred for CDC Assessment: Referred for Additional Medical Evaluation',
                   'Disposition of Travelers Referred for CDC Assessment: Other', 'Final Disposition of Traveler\'s Medical Evaluation (If applicable)',
                   'Exposure Assessment', 'Contact Made?', 'Monitoring needed?', 'Notes'].freeze

  COMPREHENSIVE_FIELDS = [:first_name, :middle_name, :last_name, :date_of_birth, :sex, :white, :black_or_african_american, :american_indian_or_alaska_native,
                          :asian, :native_hawaiian_or_other_pacific_islander, :ethnicity, :primary_language, :secondary_language, :interpretation_required,
                          :nationality, :user_defined_id_statelocal, :user_defined_id_cdc, :user_defined_id_nndss, :address_line_1, :address_city,
                          :address_state, :address_line_2, :address_zip, :address_county, :foreign_address_line_1, :foreign_address_city,
                          :foreign_address_country, :foreign_address_line_2, :foreign_address_zip, :foreign_address_line_3, :foreign_address_state,
                          :monitored_address_line_1, :monitored_address_city, :monitored_address_state, :monitored_address_line_2, :monitored_address_zip,
                          :monitored_address_county, :foreign_monitored_address_line_1, :foreign_monitored_address_city, :foreign_monitored_address_state,
                          :foreign_monitored_address_line_2, :foreign_monitored_address_zip, :foreign_monitored_address_county, :preferred_contact_method,
                          :primary_telephone, :primary_telephone_type, :secondary_telephone, :secondary_telephone_type, :preferred_contact_time, :email,
                          :port_of_origin, :date_of_departure, :source_of_report, :flight_or_vessel_number, :flight_or_vessel_carrier, :port_of_entry_into_usa,
                          :date_of_arrival, :travel_related_notes, :additional_planned_travel_type, :additional_planned_travel_destination,
                          :additional_planned_travel_destination_state, :additional_planned_travel_destination_country,
                          :additional_planned_travel_port_of_departure, :additional_planned_travel_start_date, :additional_planned_travel_end_date,
                          :additional_planned_travel_related_notes, :last_date_of_exposure, :potential_exposure_location, :potential_exposure_country,
                          :contact_of_known_case, :contact_of_known_case_id, :travel_to_affected_country_or_area, :was_in_health_care_facility_with_known_cases,
                          :was_in_health_care_facility_with_known_cases_facility_name, :laboratory_personnel, :laboratory_personnel_facility_name,
                          :healthcare_personnel, :healthcare_personnel_facility_name, :crew_on_passenger_or_cargo_flight, :member_of_a_common_exposure_cohort,
                          :member_of_a_common_exposure_cohort_type, :exposure_risk_assessment, :monitoring_plan, :exposure_notes, nil, :symptom_onset,
                          :case_status, nil, nil, nil, nil, nil, nil, nil, nil, :jurisdiction_path, :assigned_user, :gender_identity,
                          :sexual_orientation].freeze

  EPI_X_FIELDS = [:user_defined_id_statelocal, :flight_or_vessel_number, nil, nil, :user_defined_id_cdc, nil, nil, :primary_language, :date_of_arrival,
                  :port_of_entry_into_usa, :last_name, :first_name, :date_of_birth, :sex, nil, nil, :address_line_1, :address_city, :address_state,
                  :address_zip, :monitored_address_line_1, :monitored_address_city, :monitored_address_state, :monitored_address_zip, nil, nil, nil, nil,
                  :primary_telephone, :secondary_telephone, :email, nil, nil, nil, :potential_exposure_location, :potential_exposure_country,
                  :date_of_departure, nil, nil, nil, nil, :contact_of_known_case, :was_in_health_care_facility_with_known_cases].freeze

  SEX_ABBREVIATIONS = {
    M: 'Male',
    F: 'Female',
    U: 'Unknown'
  }.freeze

  STATE_ABBREVIATIONS = {
    AL: 'Alabama',
    AK: 'Alaska',
    AS: 'American Samoa',
    AZ: 'Arizona',
    AR: 'Arkansas',
    CA: 'California',
    CO: 'Colorado',
    CT: 'Connecticut',
    DE: 'Delaware',
    DC: 'District of Columbia',
    FM: 'Federated States of Micronesia',
    FL: 'Florida',
    GA: 'Georgia',
    GU: 'Guam',
    HI: 'Hawaii',
    ID: 'Idaho',
    IL: 'Illinois',
    IN: 'Indiana',
    IA: 'Iowa',
    KS: 'Kansas',
    KY: 'Kentucky',
    LA: 'Louisiana',
    ME: 'Maine',
    MH: 'Marshall Islands',
    MD: 'Maryland',
    MA: 'Massachusetts',
    MI: 'Michigan',
    MN: 'Minnesota',
    MS: 'Mississippi',
    MO: 'Missouri',
    MT: 'Montana',
    NE: 'Nebraska',
    NV: 'Nevada',
    NH: 'New Hampshire',
    NJ: 'New Jersey',
    NM: 'New Mexico',
    NY: 'New York',
    NC: 'North Carolina',
    ND: 'North Dakota',
    MP: 'Northern Mariana Islands',
    OH: 'Ohio',
    OK: 'Oklahoma',
    OR: 'Oregon',
    PW: 'Palau',
    PA: 'Pennsylvania',
    PR: 'Puerto Rico',
    RI: 'Rhode Island',
    SC: 'South Carolina',
    SD: 'South Dakota',
    TN: 'Tennessee',
    TX: 'Texas',
    UT: 'Utah',
    VT: 'Vermont',
    VI: 'Virgin Islands',
    VA: 'Virginia',
    WA: 'Washington',
    WV: 'West Virginia',
    WI: 'Wisconsin',
    WY: 'Wyoming'
  }.freeze

  VALID_STATES = STATE_ABBREVIATIONS.values

  VALID_ENUMS = {
    ethnicity: ['Not Hispanic or Latino', 'Hispanic or Latino'],
    preferred_contact_method: ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out', 'Unknown'],
    primary_telephone_type: ['Smartphone', 'Plain Cell', 'Landline'],
    secondary_telephone_type: ['Smartphone', 'Plain Cell', 'Landline'],
    preferred_contact_time: %w[Morning Afternoon Evening],
    additional_planned_travel_type: %w[Domestic International],
    exposure_risk_assessment: ['High', 'Medium', 'Low', 'No Identified Risk'],
    monitoring_plan: ['None',
                      'Daily active monitoring',
                      'Self-monitoring with public health supervision',
                      'Self-monitoring with delegated supervision',
                      'Self-observation'],
    case_status: ['Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case']
  }.freeze

  NORMALIZED_ENUMS = VALID_ENUMS.transform_values do |values|
    Hash[values.collect { |value| [value.to_s.downcase.gsub(/[ -.]/, ''), value] }]
  end

  VALIDATION = {
    first_name: { label: 'First Name', checks: [:required] },
    last_name: { label: 'Last Name', checks: [:required] },
    date_of_birth: { label: 'Date of Birth', checks: %i[required date] },
    sex: { label: 'Sex', checks: [:sex] },
    white: { label: 'White', checks: [:bool] },
    black_or_african_american: { label: 'Black or African American', checks: [:bool] },
    american_indian_or_alaska_native: { label: 'American Indian or Alaska Native', checks: [:bool] },
    asian: { label: 'Asian', checks: [:bool] },
    native_hawaiian_or_other_pacific_islander: { label: 'Native Hawaiian or Other Pacific Islander', checks: [:bool] },
    ethnicity: { label: 'Ethnicity', checks: [:enum] },
    interpretation_required: { label: 'Interpretation Required?', checks: [:bool] },
    address_state: { label: 'State', checks: [:state] },
    monitored_address_state: { label: 'Monitored Address State', checks: [:state] },
    foreign_monitored_address_state: { label: 'Foreign Monitored Address State', checks: [:state] },
    preferred_contact_method: { label: 'Preferred Contact Method', checks: [:enum] },
    primary_telephone: { label: 'Primary Telephone', checks: [:phone] },
    primary_telephone_type: { label: 'Primary Telephone Type', checks: [:enum] },
    secondary_telephone: { label: 'Secondary Telephone', checks: [:phone] },
    secondary_telephone_type: { label: 'Secondary Telephone Type', checks: [:enum] },
    preferred_contact_time: { label: 'Preferred Contact Time', checks: [:enum] },
    email: { label: 'Email', checks: [:email] },
    date_of_departure: { label: 'Date of Departure', checks: [:date] },
    date_of_arrival: { label: 'Date of Arrival', checks: [:date] },
    additional_planned_travel_type: { label: 'Additional Planned Travel Type', checks: [:enum] },
    additional_planned_travel_destination_state: { label: 'Additional Planned Travel Destination State', checks: [:state] },
    additional_planned_travel_start_date: { label: 'Additional Planned Travel Start Date', checks: [:date] },
    additional_planned_travel_end_date: { label: 'Additional Planned Travel End Date', checks: [:date] },
    last_date_of_exposure: { label: 'Last Date of Exposure', checks: %i[required date] },
    contact_of_known_case: { label: 'Contact of Known Case?', checks: [:bool] },
    travel_to_affected_country_or_area: { label: 'Travel from Affected Country or Area?', checks: [:bool] },
    was_in_health_care_facility_with_known_cases: { label: 'Was in Health Care Facility With Known Cases?', checks: [:bool] },
    laboratory_personnel: { label: 'Laboratory Personnel?', checks: [:bool] },
    healthcare_personnel: { label: 'Healthcare Personnel?', checks: [:bool] },
    crew_on_passenger_or_cargo_flight: { label: 'Crew on Passenger or Cargo Flight?', checks: [:bool] },
    member_of_a_common_exposure_cohort: { label: 'Member of a Common Exposure Cohort?', checks: [:bool] },
    exposure_risk_assessment: { label: 'Exposure Risk Assessment', checks: [:enum] },
    monitoring_plan: { label: 'Monitoring Plan', checks: [:enum] },
    symptom_onset: { label: 'Symptom Onset', checks: [:date] },
    case_status: { label: 'Case Status', checks: [:enum] },
    specimen_collection: { label: 'Lab Specimen Collection Date', checks: [:date] },
    report: { label: 'Lab Report Date', checks: [:date] }
  }.freeze

  def unformat_enum_field(value)
    value.to_s.downcase.gsub(/[ -.]/, '')
  end

  def csv_line_list(patients)
    package = CSV.generate(headers: true) do |csv|
      csv << LINELIST_HEADERS
      statuses = patient_statuses(patients)
      patients.find_in_batches(batch_size: 500) do |patients_group|
        linelists = linelists_for_export(patients_group, statuses)
        patients_group.each do |patient|
          csv << linelists[patient.id].values
        end
      end
    end
    Base64.encode64(package)
  end

  def sara_alert_format(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Monitorees') do |sheet|
        sheet.add_row COMPREHENSIVE_HEADERS
        statuses = patient_statuses(patients)
        patients.find_in_batches(batch_size: 500) do |patients_group|
          comprehensive_details = comprehensive_details_for_export(patients_group, statuses)
          patients_group.each do |patient|
            sheet.add_row comprehensive_details[patient.id].values, { types: Array.new(COMPREHENSIVE_HEADERS.length, :string) }
          end
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  def excel_export(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Monitorees List') do |sheet|
        headers = MONITOREES_LIST_HEADERS
        sheet.add_row headers
        statuses = patient_statuses(patients)
        patients.find_in_batches(batch_size: 500) do |patients_group|
          comprehensive_details = comprehensive_details_for_export(patients_group, statuses)
          patients_group.each do |patient|
            sheet.add_row [patient.id] + comprehensive_details[patient.id].values, { types: Array.new(MONITOREES_LIST_HEADERS.length, :string) }
          end
        end
      end
      p.workbook.add_worksheet(name: 'Assessments') do |sheet|
        # headers and all unique symptoms
        symptom_labels = patients.joins(assessments: [{ reported_condition: :symptoms }]).select('symptoms.label').distinct.pluck('symptoms.label').sort
        sheet.add_row ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels.to_a.sort

        # assessments sorted by patients
        patients.find_in_batches(batch_size: 500) do |patients_group|
          assessments = Assessment.where(patient_id: patients_group.pluck(:id))
          conditions = ReportedCondition.where(assessment_id: assessments.pluck(:id))
          symptoms = Symptom.where(condition_id: conditions.pluck(:id))

          # construct hash containing symptoms by assessment_id
          conditions_hash = Hash[conditions.pluck(:id, :assessment_id).map { |id, assessment_id| [id, assessment_id] }]
                            .transform_values { |assessment_id| { assessment_id: assessment_id, symptoms: {} } }
          symptoms.each do |symptom|
            conditions_hash[symptom[:condition_id]][:symptoms][symptom[:label]] = symptom.value
          end
          assessments_hash = Hash[conditions_hash.map { |_, condition| [condition[:assessment_id], condition[:symptoms]] }]

          # combine symptoms with assessment summary
          assessment_summary_arrays = assessments.order(:patient_id, :id).pluck(:id, :patient_id, :symptomatic, :who_reported, :created_at, :updated_at)
          assessment_summary_arrays.each do |assessment_summary_array|
            symptoms_hash = assessments_hash[assessment_summary_array[0]]
            next if symptoms_hash.nil?

            symptoms_array = symptom_labels.map { |symptom_label| symptoms_hash[symptom_label].to_s }
            row = assessment_summary_array[1..].concat(symptoms_array)
            sheet.add_row row, { types: Array.new(row.length, :string) }
          end
        end
      end
      p.workbook.add_worksheet(name: 'Lab Results') do |sheet|
        labs = Laboratory.where(patient_id: patients.pluck(:id))
        lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result Date', 'Created At', 'Updated At']
        sheet.add_row lab_headers
        labs.find_each(batch_size: 500) do |lab|
          sheet.add_row lab.details.values, { types: Array.new(lab_headers.length, :string) }
        end
      end
      p.workbook.add_worksheet(name: 'Edit Histories') do |sheet|
        histories = History.where(patient_id: patients.pluck(:id))
        history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
        sheet.add_row history_headers
        histories.find_each(batch_size: 500) do |history|
          sheet.add_row history.details.values, { types: Array.new(history_headers.length, :string) }
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  def excel_export_monitorees(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Monitorees List') do |sheet|
        headers = MONITOREES_LIST_HEADERS
        sheet.add_row headers
        statuses = patient_statuses(patients)
        patients.find_in_batches(batch_size: 500) do |patients_group|
          comprehensive_details = comprehensive_details_for_export(patients_group, statuses)
          patients_group.each do |patient|
            sheet.add_row [patient.id] + comprehensive_details[patient.id].values, { types: Array.new(MONITOREES_LIST_HEADERS.length, :string) }
          end
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  def excel_export_assessments(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Assessments') do |sheet|
        # headers and all unique symptoms
        symptom_labels = patients.joins(assessments: [{ reported_condition: :symptoms }]).select('symptoms.label').distinct.pluck('symptoms.label').sort
        sheet.add_row ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels.to_a.sort

        # assessments sorted by patients
        patients.find_in_batches(batch_size: 500) do |patients_group|
          assessments = Assessment.where(patient_id: patients_group.pluck(:id))
          conditions = ReportedCondition.where(assessment_id: assessments.pluck(:id))
          symptoms = Symptom.where(condition_id: conditions.pluck(:id))

          # construct hash containing symptoms by assessment_id
          conditions_hash = Hash[conditions.pluck(:id, :assessment_id).map { |id, assessment_id| [id, assessment_id] }]
                            .transform_values { |assessment_id| { assessment_id: assessment_id, symptoms: {} } }
          symptoms.each do |symptom|
            conditions_hash[symptom[:condition_id]][:symptoms][symptom[:label]] = symptom.value
          end
          assessments_hash = Hash[conditions_hash.map { |_, condition| [condition[:assessment_id], condition[:symptoms]] }]

          # combine symptoms with assessment summary
          assessment_summary_arrays = assessments.order(:patient_id, :id).pluck(:id, :patient_id, :symptomatic, :who_reported, :created_at, :updated_at)
          assessment_summary_arrays.each do |assessment_summary_array|
            symptoms_hash = assessments_hash[assessment_summary_array[0]]
            next if symptoms_hash.nil?

            symptoms_array = symptom_labels.map { |symptom_label| symptoms_hash[symptom_label].to_s }
            row = assessment_summary_array[1..].concat(symptoms_array)
            sheet.add_row row, { types: Array.new(row.length, :string) }
          end
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  def excel_export_lab_results(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Lab Results') do |sheet|
        labs = Laboratory.where(patient_id: patients.pluck(:id))
        lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result Date', 'Created At', 'Updated At']
        sheet.add_row lab_headers
        labs.find_each(batch_size: 500) do |lab|
          sheet.add_row lab.details.values, { types: Array.new(lab_headers.length, :string) }
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  def excel_export_histories(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Edit Histories') do |sheet|
        histories = History.where(patient_id: patients.pluck(:id))
        history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
        sheet.add_row history_headers
        histories.find_each(batch_size: 500) do |history|
          sheet.add_row history.details.values, { types: Array.new(history_headers.length, :string) }
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  # Patient fields relevant to linelist export
  def linelists_for_export(patients, statuses)
    linelists = incomplete_linelists_for_export(patients)
    patients_jurisdiction_names = jurisdiction_names(patients)
    patients_transfers = latest_transfers(patients)
    patients.each do |patient|
      linelists[patient.id][:jurisdiction] = patients_jurisdiction_names[patient.id]
      linelists[patient.id][:status] = statuses[patient.id]&.gsub('exposure ', '')&.gsub('isolation ', '')
      next unless patients_transfers[patient.id]

      %i[transferred_at transferred_from transferred_to].each do |transfer_field|
        linelists[patient.id][transfer_field] = patients_transfers[patient.id][transfer_field]
      end
    end
    linelists
  end

  # Patient fields relevant to sara alert format and excel export
  def comprehensive_details_for_export(patients, statuses)
    comprehensive_details = incomplete_comprehensive_details_for_export(patients)
    patients_jurisdiction_paths = jurisdiction_paths(patients)
    patients_labs = latest_laboratories(patients)
    patients.each do |patient|
      comprehensive_details[patient.id][:jurisdiction_path] = patients_jurisdiction_paths[patient.id]
      comprehensive_details[patient.id][:status] = statuses[patient.id]
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

  # Status of each patient (faster to do this in bulk than individually for exports)
  def patient_statuses(patients)
    tabs = {
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
    statuses = {}
    tabs.each do |tab, patient_ids|
      patient_ids.each do |patient_id|
        statuses[patient_id] = tab&.to_s&.humanize&.downcase
      end
    end
    statuses
  end

  # Latest transfer of each patient
  def latest_transfers(patients)
    latest_transfers = patients.pluck(:id, :latest_transfer_at)
    transfers = Transfer.where(patient_id: latest_transfers.map { |lt| lt[0] }, created_at: latest_transfers.map { |lt| lt[1] })
    jurisdictions = Jurisdiction.find(transfers.pluck(:from_jurisdiction_id, :to_jurisdiction_id).flatten.uniq)
    jurisdiction_paths = Hash[jurisdictions.pluck(:id, :path).map { |id, path| [id, path] }]
    Hash[transfers.pluck(:patient_id, :created_at, :from_jurisdiction_id, :to_jurisdiction_id)
                  .map do |patient_id, created_at, from_jurisdiction_id, to_jurisdiction_id|
                    [patient_id, {
                      transferred_at: created_at.rfc2822,
                      transferred_from: jurisdiction_paths[from_jurisdiction_id],
                      transferred_to: jurisdiction_paths[to_jurisdiction_id]
                    }]
                  end
        ]
  end

  # 2 Latest laboratories of each patient
  def latest_laboratories(patients)
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

  # Hash containing mappings between jurisdiction id and path for each patient
  def jurisdiction_paths(patients)
    jurisdiction_paths = Hash[Jurisdiction.find(patients.pluck(:jurisdiction_id).uniq).pluck(:id, :path).map { |id, path| [id, path] }]
    patients_jurisdiction_paths = {}
    patients.each do |patient|
      patients_jurisdiction_paths[patient.id] = jurisdiction_paths[patient.jurisdiction_id]
    end
    patients_jurisdiction_paths
  end

  # Hash containing mappings between jurisdiction id and name for each patient
  def jurisdiction_names(patients)
    jurisdiction_names = Hash[Jurisdiction.find(patients.pluck(:jurisdiction_id).uniq).pluck(:id, :name).map { |id, name| [id, name] }]
    patients_jurisdiction_names = {}
    patients.each do |patient|
      patients_jurisdiction_names[patient.id] = jurisdiction_names[patient.jurisdiction_id]
    end
    patients_jurisdiction_names
  end

  # Converts phone number from e164 to CDC recommended format
  def format_phone_number(phone)
    cleaned_phone_number = Phonelib.parse(phone).national(false)
    return nil if cleaned_phone_number.nil? || cleaned_phone_number.length != 10

    cleaned_phone_number.insert(6, '-').insert(3, '-')
  end

  # Linelist fields obtainable without any joins
  def incomplete_linelists_for_export(patients)
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
        end_of_monitoring: patient.end_of_monitoring,
        risk_level: patient[:exposure_risk_assessment] || '',
        monitoring_plan: patient[:monitoring_plan] || '',
        latest_report: patient[:latest_assessment_at]&.rfc2822,
        transferred_at: '',
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

  # Comprehensive details fields obtainable without any joins
  def incomplete_comprehensive_details_for_export(patients)
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
        primary_telephone: patient[:primary_telephone] ? format_phone_number(patient[:primary_telephone]) : '',
        primary_telephone_type: patient[:primary_telephone_type] || '',
        secondary_telephone: patient[:secondary_telephone] ? format_phone_number(patient[:secondary_telephone]) : '',
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
        assigned_user: patient[:assigned_user] || '',
        gender_identity: patient[:gender_identity] || '',
        sexual_orientation: patient[:sexual_orientation] || ''
      }
    end
    comprehensive_details
  end
end
