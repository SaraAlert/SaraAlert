# frozen_string_literal: true

# Helper methods for the import and export controllers
module ImportExport # rubocop:todo Metrics/ModuleLength
  include ValidationHelper

  PATIENT_FIELD_NAMES = {
    # Enrollment Info - Identification - Name
    first_name: 'First Name',
    middle_name: 'Middle Name',
    last_name: 'Last Name',
    # Enrollment Info - Identification - Date of Birth and Age
    date_of_birth: 'Date of Birth',
    age: 'Age',
    # Enrollment Info - Identification - Sex, Gender Identity, and Sexual Orientation
    sex: 'Sex at Birth',
    gender_identity: 'Gender Identity',
    sexual_orientation: 'Sexual Orientation',
    # Enrollment Info - Identification - Race, Ethnicity, and Nationality
    white: 'White?',
    black_or_african_american: 'Black or African American?',
    american_indian_or_alaska_native: 'American Indian or Alaska Native?',
    asian: 'Asian?',
    native_hawaiian_or_other_pacific_islander: 'Native Hawaiian or Other Pacific Islander?',
    ethnicity: 'Ethnicity',
    nationality: 'Nationality',
    # Enrollment Info - Identification - Language
    primary_language: 'Primary Language',
    secondary_language: 'Secondary Language',
    interpretation_required: 'Interpretation Required?',
    # Enrollment Info - Identification - State/Local, CDC, and NNDSS IDs
    user_defined_id_statelocal: 'Identifier (STATE/LOCAL)',
    user_defined_id_cdc: 'Identifier (CDC)',
    user_defined_id_nndss: 'Identifier (NNDSS)',
    # Enrollment Info - Address - Home Address (USA)
    address_line_1: 'Address Line 1',
    address_city: 'Address City',
    address_state: 'Address State',
    address_line_2: 'Address Line 2',
    address_zip: 'Address Zip',
    address_county: 'Address County',
    # Enrollment Info - Address - Home Address (Foreign)
    foreign_address_line_1: 'Foreign Address Line 1',
    foreign_address_city: 'Foreign Address City',
    foreign_address_country: 'Foreign Address Country',
    foreign_address_line_2: 'Foreign Address Line 2',
    foreign_address_zip: 'Foreign Address Zip',
    foreign_address_line_3: 'Foreign Address Line 3',
    foreign_address_state: 'Foreign Address State',
    # Enrollment Info - Address - Monitored Address (USA)
    monitored_address_line_1: 'Monitored Address Line 1',
    monitored_address_city: 'Monitored Address City',
    monitored_address_state: 'Monitored Address State',
    monitored_address_line_2: 'Monitored Address Line 2',
    monitored_address_zip: 'Monitored Address Zip',
    monitored_address_county: 'Monitored Address County',
    # Enrollment Info - Address - Monitored Address (Foreign)
    foreign_monitored_address_line_1: 'Foreign Monitored Address Line 1',
    foreign_monitored_address_city: 'Foreign Monitored Address City',
    foreign_monitored_address_state: 'Foreign Monitored Address State',
    foreign_monitored_address_line_2: 'Foreign Monitored Address Line 2',
    foreign_monitored_address_zip: 'Foreign Monitored Address Zip',
    foreign_monitored_address_county: 'Foreign Monitored Address County',
    # Enrollment Info - Contact Information
    preferred_contact_method: 'Preferred Contact Method',
    preferred_contact_time: 'Preferred Contact Time',
    primary_telephone: 'Primary Telephone',
    primary_telephone_type: 'Primary Telephone Type',
    secondary_telephone: 'Secondary Telephone',
    secondary_telephone_type: 'Secondary Telephone Type',
    email: 'Email',
    # Enrollment Info - Arrival Information
    port_of_origin: 'Port of Origin',
    date_of_departure: 'Date of Departure',
    flight_or_vessel_number: 'Flight or Vessel Number',
    flight_or_vessel_carrier: 'Flight or Vessel Carrier',
    port_of_entry_into_usa: 'Port of Entry Into USA',
    date_of_arrival: 'Date of Arrival',
    source_of_report: 'Source of Report',
    source_of_report_specify: 'Source of Report Specify',
    travel_related_notes: 'Travel Related Notes',
    # Enrollment Info - Additional Planned Travel
    additional_planned_travel_type: 'Additional Planned Travel Type',
    additional_planned_travel_destination: 'Additional Planned Travel Destination',
    additional_planned_travel_destination_state: 'Additional Planned Travel Destination State',
    additional_planned_travel_destination_country: 'Additional Planned Travel Destination Country',
    additional_planned_travel_port_of_departure: 'Additional Planned Travel Port of Departure',
    additional_planned_travel_start_date: 'Additional Planned Travel Start Date',
    additional_planned_travel_end_date: 'Additional Planned Travel End Date',
    additional_planned_travel_related_notes: 'Additional Planned Travel Related Notes',
    # Enrollment Info - Potential Exposure Information - Exposure Location and Notes
    potential_exposure_location: 'Potential Exposure Location',
    potential_exposure_country: 'Potential Exposure Country',
    exposure_notes: 'Exposure Notes',
    # Enrollment Info - Potential Exposure Information - Risk Factors
    contact_of_known_case: 'Contact of Known Case?',
    contact_of_known_case_id: 'Contact of Known Case ID',
    travel_to_affected_country_or_area: 'Travel from Affected Country or Area?',
    was_in_health_care_facility_with_known_cases: 'Was in Health Care Facility With Known Cases?',
    was_in_health_care_facility_with_known_cases_facility_name: 'Health Care Facility with Known Cases Name',
    laboratory_personnel: 'Laboratory Personnel?',
    laboratory_personnel_facility_name: 'Laboratory Personnel Facility Name',
    healthcare_personnel: 'Health Care Personnel?',
    healthcare_personnel_facility_name: 'Health Care Personnel Facility Name',
    crew_on_passenger_or_cargo_flight: 'Crew on Passenger or Cargo Flight?',
    member_of_a_common_exposure_cohort: 'Member of a Common Exposure Cohort?',
    member_of_a_common_exposure_cohort_type: 'Common Exposure Cohort Name',
    # Monitoring Info - Linelist Info
    name: 'Monitoree',
    isolation: 'Isolation?',
    status: 'Status',
    latest_assessment_at: 'Latest Assessment At',
    latest_fever_or_fever_reducer_at: 'Latest Fever or Fever Reducer At',
    latest_positive_lab_at: 'Latest Positive Lab At',
    negative_lab_count: 'Negative Lab Count',
    latest_transfer_at: 'Latest Transfer At',
    latest_transfer_from: 'Latest Transfer From',
    latest_transfer_to: 'Latest Transfer To',
    # Monitoring Info - Monitoring Actions
    monitoring_status: 'Monitoring?',
    exposure_risk_assessment: 'Exposure Risk Assessment',
    monitoring_plan: 'Monitoring Plan',
    case_status: 'Case Status',
    public_health_action: 'Latest Public Health Action',
    jurisdiction_path: 'Full Assigned Jurisdiction Path',
    jurisdiction_name: 'Jurisdiction',
    assigned_user: 'Assigned User',
    # Monitoring Info - Monitoring Period
    last_date_of_exposure: 'Last Date of Exposure',
    continuous_exposure: 'Continuous Exposure?',
    symptom_onset: 'Symptom Onset Date',
    user_defined_symptom_onset: 'User Defined Symptom Onset?',
    extended_isolation: 'Extended Isolation',
    end_of_monitoring: 'End of Monitoring',
    closed_at: 'Closed At',
    monitoring_reason: 'Reason For Closure',
    expected_purge_date: 'Expected Purge Date',
    # Monitoring Info - Reporting Info
    responder_id: 'Responder ID',
    head_of_household: 'Head of Household?',
    contact_attempts: 'Contact Attempts',
    pause_notifications: 'Pause Notifications?',
    last_assessment_reminder_sent: 'Last Assessment Reminder Sent',
    # Metadata,
    id: 'Monitoree ID',
    creator: 'Enroller',
    created_at: 'Created At',
    updated_at: 'Updated At'
  }.freeze

  ASSESSMENT_FIELD_NAMES = {
    id: 'Assessment ID',
    patient_id: 'Patient ID',
    symptomatic: 'Needs Review',
    who_reported: 'Who Reported',
    created_at: 'Created At',
    updated_at: 'Updated At',
    symptoms: 'Symptoms'
  }.freeze

  LABORATORY_FIELD_NAMES = {
    id: 'Laboratory ID',
    patient_id: 'Patient ID',
    lab_type: 'Lab Type',
    specimen_collection: 'Specimen Collection Date',
    report: 'Report Date',
    result: 'Result',
    created_at: 'Created At',
    updated_at: 'Updated At'
  }.freeze

  CLOSE_CONTACT_FIELD_NAMES = {
    id: 'Close Contact ID',
    patient_id: 'Patient ID',
    first_name: 'First Name',
    last_name: 'Last Name',
    primary_telephone: 'Primary Telephone',
    email: 'Email',
    contact_attempts: 'Contact Attempts',
    notes: 'Notes',
    enrolled_id: 'Enrolled ID',
    created_at: 'Created At',
    updated_at: 'Updated At'
  }.freeze

  TRANSFER_FIELD_NAMES = {
    id: 'Transfer ID',
    patient_id: 'Patient ID',
    who: 'Who',
    from_jurisdiction: 'From Jurisdiction',
    to_jurisdiction: 'To Jurisdiction',
    created_at: 'Created At',
    updated_at: 'Updated At'
  }.freeze

  HISTORY_FIELD_NAMES = {
    id: 'History ID',
    patient_id: 'Patient ID',
    created_by: 'Created By',
    history_type: 'History Type',
    comment: 'Comment',
    created_at: 'Created At',
    updated_at: 'Updated At'
  }.freeze

  ALL_FIELDS_NAMES = {
    patients: PATIENT_FIELD_NAMES,
    assessments: ASSESSMENT_FIELD_NAMES,
    laboratories: LABORATORY_FIELD_NAMES,
    close_contacts: CLOSE_CONTACT_FIELD_NAMES,
    transfers: TRANSFER_FIELD_NAMES,
    histories: HISTORY_FIELD_NAMES
  }.freeze

  # Creates react checkbox tree node with children populated
  def self.rct_node(schema, label, fields)
    return if ALL_FIELDS_NAMES[schema].nil?

    {
      value: "#{schema}-#{label&.gsub(' ', '_')&.gsub(',', '')&.downcase}",
      label: label,
      children: fields.map { |field| { value: field&.to_s, label: ALL_FIELDS_NAMES[schema][field] } }
    }
  end

  PATIENTS_EXPORT_OPTIONS = {
    nodes: [
      {
        value: 'patients',
        label: 'Export Monitorees',
        children: [
          {
            value: 'patients-enrollment',
            label: 'Enrollment Info',
            children: [
              {
                value: 'patients-enrollment-identification',
                label: 'Identification',
                children: [
                  rct_node(:patients, 'Name', %i[first_name last_name middle_name]),
                  rct_node(:patients, 'Date of Birth and Age', %i[date_of_birth age]),
                  rct_node(:patients, 'Sex, Gender Identity, and Sexual Orientation', %i[sex gender_identity sexual_orientation]),
                  rct_node(:patients, 'Race, Ethnicity, and Nationality', %i[white black_or_african_american american_indian_or_alaska_native asian
                                                                             native_hawaiian_or_other_pacific_islander ethnicity nationality]),
                  rct_node(:patients, 'Language', %i[primary_language secondary_language interpretation_required]),
                  rct_node(:patients, 'State/Local, CDC, and NNDSS IDs', %i[user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss])
                ]
              },
              {
                value: 'patients-enrollment-address',
                label: 'Address',
                children: [
                  rct_node(:patients, 'Home Address (USA)', %i[address_line_1 address_city address_state address_line_2 address_zip address_county]),
                  rct_node(:patients, 'Home Address (Foreign)', %i[foreign_address_line_1 foreign_address_city foreign_address_country foreign_address_line_2
                                                                   foreign_address_zip foreign_address_line_3 foreign_address_state]),
                  rct_node(:patients, 'Monitored Address (USA)', %i[monitored_address_line_1 monitored_address_city monitored_address_state
                                                                    monitored_address_line_2 monitored_address_zip monitored_address_county]),
                  rct_node(:patients, 'Monitored Address (Foreign)', %i[foreign_monitored_address_line_1 foreign_monitored_address_city
                                                                        foreign_monitored_address_state foreign_monitored_address_line_2
                                                                        foreign_monitored_address_zip foreign_monitored_address_county])
                ]
              },
              rct_node(:patients, 'Contact Information', %i[preferred_contact_method preferred_contact_time primary_telephone primary_telephone_type
                                                            secondary_telephone secondary_telephone_type email]),
              rct_node(:patients, 'Arrival Information', %i[port_of_origin date_of_departure flight_or_vessel_number flight_or_vessel_carrier
                                                            port_of_entry_into_usa date_of_arrival source_of_report source_of_report_specify
                                                            travel_related_notes]),
              rct_node(:patients, 'Additional Planned Travel', %i[additional_planned_travel_type additional_planned_travel_destination
                                                                  additional_planned_travel_destination_state additional_planned_travel_destination_country
                                                                  additional_planned_travel_port_of_departure additional_planned_travel_start_date
                                                                  additional_planned_travel_end_date additional_planned_travel_related_notes]),
              {
                value: 'patients-enrollment-potential_exposure_information',
                label: 'Potential Exposure Information',
                children: [
                  rct_node(:patients, 'Exposure Location and Notes', %i[potential_exposure_location potential_exposure_country exposure_notes]),
                  rct_node(:patients, 'Exposure Risk Factors', %i[contact_of_known_case contact_of_known_case_id travel_to_affected_country_or_area
                                                                  was_in_health_care_facility_with_known_cases
                                                                  was_in_health_care_facility_with_known_cases_facility_name laboratory_personnel
                                                                  laboratory_personnel_facility_name healthcare_personnel healthcare_personnel_facility_name
                                                                  crew_on_passenger_or_cargo_flight member_of_a_common_exposure_cohort
                                                                  member_of_a_common_exposure_cohort_type])
                ]
              },
              rct_node(:patients, 'Metadata', %i[creator created_at updated_at])
            ]
          },
          {
            value: 'patients-monitoring',
            label: 'Monitoring Info',
            children: [
              rct_node(:patients, 'Linelist Info', %i[name isolation status latest_assessment_at latest_fever_or_fever_reducer_at latest_positive_lab_at
                                                      negative_lab_count latest_transfer_at latest_transfer_from latest_transfer_to]),
              rct_node(:patients, 'Monitoring Actions', %i[monitoring_status exposure_risk_assessment monitoring_plan case_status public_health_action
                                                           jurisdiction_path jurisdiction_name assigned_user]),
              rct_node(:patients, 'Monitoring Period', %i[last_date_of_exposure continuous_exposure symptom_onset user_defined_symptom_onset
                                                          extended_isolation end_of_monitoring closed_at monitoring_reason expected_purge_date]),
              rct_node(:patients, 'Reporting Info', %i[responder_id head_of_household contact_attempts pause_notifications last_assessment_reminder_sent])
            ]
          }
        ]
      }
    ],
    checked: PATIENT_FIELD_NAMES.keys,
    expanded: %w[patients patients-enrollment patients-monitoring]
  }.freeze

  ASSESSMENTS_EXPORT_OPTIONS = {
    nodes: [rct_node(:assessments, 'Export Reports', %i[symptomatic who_reported created_at updated_at symptoms])],
    checked: [],
    expanded: %w[assessments],
    filters: {
      symptomatic: {
        label: 'Needs Review',
        options: [
          { value: 'assessments-status-needs-review', label: 'Needs Review' },
          { value: 'assessments-status-reviewed', label: 'Reviewed' }
        ]
      },
      who_reported: {
        options: [
          { value: 'assessments-reporter-monitoree', label: 'Monitoree' },
          { value: 'assessments-reporter-user', label: 'User' }
        ]
      }
    }
  }.freeze

  LABORATORIES_EXPORT_OPTIONS = {
    nodes: [rct_node(:laboratories, 'Export Lab Results', %i[lab_type specimen_collection report result created_at updated_at])],
    checked: [],
    expanded: %w[laboratories],
    filters: {
      lab_type: {
        label: 'lab type',
        options: [
          { value: 'laboratories-type-pcr', label: 'PCR' },
          { value: 'laboratories-type-antigen', label: 'Antigen' },
          { value: 'laboratories-type-total-antibody', label: 'Total Antibody' },
          { value: 'laboratories-type-igg-antibody', label: 'IgG Antibody' },
          { value: 'laboratories-type-igm-antibody', label: 'IgM Antibody' },
          { value: 'laboratories-type-iga-antibody', label: 'IgA Antibody' },
          { value: 'laboratories-type-other', label: 'Other' },
          { value: 'laboratories-type-blank', label: 'Blank' }
        ]
      },
      result: {
        label: 'result',
        options: [
          { value: 'laboratories-result-positive', label: 'Positive' },
          { value: 'laboratories-result-negative', label: 'Negative' },
          { value: 'laboratories-result-indeterminate', label: 'Indeterminate' },
          { value: 'laboratories-result-other', label: 'Other' },
          { value: 'laboratories-result-blank', label: 'Blank' }
        ]
      }
    }
  }.freeze

  CLOSE_CONTACTS_EXPORT_OPTIONS = {
    nodes: [rct_node(:close_contacts, 'Export Close Contacts', %i[first_name last_name primary_telephone email contact_attempts notes enrolled_id])],
    checked: [],
    expanded: %w[close_contacts],
    filters: {
      enrolled_id: {
        label: 'enrolled id',
        options: [
          { value: 'close_contacts-type-enrolled', label: 'Enrolled' },
          { value: 'close_contacts-type-not-enrolled', label: 'Not Enrolled' }
        ]
      }
    }
  }.freeze

  TRANSFERS_EXPORT_OPTIONS = {
    nodes: [rct_node(:transfers, 'Export Transfers', %i[who from_jurisdiction to_jurisdiction created_at updated_at])],
    checked: [],
    expanded: %w[transfers],
    filters: []
  }.freeze

  HISTORIES_EXPORT_OPTIONS = {
    nodes: [rct_node(:histories, 'Export History', %i[created_by history_type comment created_at updated_at])],
    checked: [],
    expanded: %w[histories],
    filters: {
      history_type: {
        label: 'history type',
        options: History::HISTORY_TYPES.map { |type, label| { value: "histories-type-#{type}", label: label } }
      },
      created_by: {
        label: 'creator',
        options: [
          { value: 'histories-creator-sara-alert-system', label: 'Sara Alert System' },
          { value: 'histories-creator-user', label: 'User' }
        ]
      }
    }
  }.freeze

  CUSTOM_EXPORT_OPTIONS = {
    patients: PATIENTS_EXPORT_OPTIONS,
    assessments: ASSESSMENTS_EXPORT_OPTIONS,
    laboratories: LABORATORIES_EXPORT_OPTIONS,
    close_contacts: CLOSE_CONTACTS_EXPORT_OPTIONS,
    transfers: TRANSFERS_EXPORT_OPTIONS,
    histories: HISTORIES_EXPORT_OPTIONS
  }.freeze

  EXPORT_FORMATS = %w[csv xlsx].freeze

  LINELIST_HEADERS = ['Patient ID', 'Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level',
                      'Monitoring Plan', 'Latest Report', 'Transferred At', 'Reason For Closure', 'Latest Public Health Action', 'Status', 'Closed At',
                      'Transferred From', 'Transferred To', 'Expected Purge Date', 'Symptom Onset', 'Extended Isolation'].freeze

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
                           'Exposure Risk Assessment', 'Monitoring Plan', 'Exposure Notes', 'Status', 'Symptom Onset Date',
                           'Case Status', 'Lab 1 Test Type', 'Lab 1 Specimen Collection Date', 'Lab 1 Report Date', 'Lab 1 Result', 'Lab 2 Test Type',
                           'Lab 2 Specimen Collection Date', 'Lab 2 Report Date', 'Lab 2 Result', 'Full Assigned Jurisdiction Path', 'Assigned User',
                           'Gender Identity', 'Sexual Orientation'].freeze

  MONITOREES_LIST_HEADERS = ['Patient ID'] + COMPREHENSIVE_HEADERS + ['Extended Isolation Date'].freeze

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

  LINELIST_FIELDS = %i[id name jurisdiction assigned_user user_defined_id_statelocal sex date_of_birth end_of_monitoring risk_level monitoring_plan
                       latest_report transferred_at monitoring_reason public_health_action status closed_at transferred_from transferred_to expected_purge_date
                       symptom_onset extended_isolation].freeze

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

  def unformat_enum_field(value)
    value.to_s.downcase.gsub(/[ -.]/, '')
  end

  def validate_checked_fields(checked)
    raise StandardError('Checked must be an array') unless checked.is_a?(Array)
  end

  def csv_export(patients, fields)
    package = CSV.generate(headers: true) do |csv|
      csv << fields.map { |field| PATIENT_FIELDS[field] }
      patients.find_in_batches(batch_size: 500) do |patients_group|
        patients_details = extract_patient_details_in_batch(patients_group, fields)
        patients_details.each do |patient_details|
          csv << fields.map { |field| patient_details[field] }
        end
      end
    end
    Base64.encode64(package)
  end

  def xlsx_export(patients, fields)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: data_type) do |sheet|
        sheet.add_row(fields.map { |field| PATIENT_FIELDS[field] })
        patients.find_in_batches(batch_size: 500) do |patients_group|
          patients_details = extract_patient_details_in_batch(patients_group, fields)
          patients_details.each do |patient_details|
            sheet.add_row(fields.map { |field| patient_details[field] }, { types: Array.new(fields.length, :string) })
          end
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  def extract_patient_details_in_batch(patients_group, fields)
    # perform the following queries in bulk only if requested for better performance
    patients_statuses = statuses(patients) if fields.include?(:status)
    patients_jurisdiction_names = jurisdiction_names(patients) if fields.include?(:jurisdiction)
    patients_jurisdiction_paths = jurisdiction_paths(patients) if fields.include?(:jurisdiction_path)
    patients_transfers = transfers(patients) if (fields & %i[transferred_from transferred_to]).any?
    lab_fields = %i[lab_1_type lab_1_specimen_collection lab_1_report lab_1_result lab_2_type lab_2_specimen_collection lab_2_report lab_2_result]
    patients_labs = laboratories(patients) if (fields & lab_fields).any?

    # construct patient details
    patients_details = []
    patients_group.each do |patient|
      # populate requested inherent fields
      patient_details = extract_incomplete_patient_details(patient, fields)

      # populate computed fields if requested
      patient_details[:name] = patient.displayed_name || '' if fields.include?(:name)
      patient_details[:jurisdiction] = patients_jurisdiction_names[patient.id] || '' if fields.include?(:jurisdiction)
      patient_details[:jurisdiction_path] = patients_jurisdiction_paths[patient.id] || '' if fields.include?(:jurisdiction_path)
      patient_details[:status] = patients_statuses[patient.id] || '' if fields.include?(:status)
      patient_details[:end_of_monitoring] = patient.end_of_monitoring || '' if fields.include?(:end_of_monitoring)
      patient_details[:expected_purge_date] = patient.expected_purge_date || '' if fields.include?(:expected_purge_date)
      patient_details[:latest_report] = patient[:latest_assessment_at]&.strftime('%F') || '' if fields.include?(:latest_report)
      patient_details[:transferred_at] = patient[:latest_transfer_at]&.strftime('%F') || '' if fields.include?(:transferred_at)

      # populate latest transfer from and to if requested
      if patients_transfers.key?(patient.id)
        patient_details[:transferred_from] = patients_transfers[patient.id][:trasnferred_from] if fields.include?(:transferred_from)
        patient_details[:transferred_to] = patients_transfer[patient.id][:transferred_to] if fields.include?(:transferred_to)
      end

      # populate labs if requested
      if patients_labs.key?(patient.id)
        if patients_labs[patient.id].key?(:first)
          patient_details[:lab_1_type] = patients_labs[patient.id][:first][:lab_type] || '' if fields.include?(:lab_1_type)
          if fields.include?(:lab_1_specimen_collection)
            patient_details[:lab_1_specimen_collection] = patients_labs[patient.id][:first][:specimen_collection]&.strftime('%F') || ''
          end
          patient_details[:lab_1_report] = patients_labs[patient.id][:first][:report]&.strftime('%F') || '' if fields.include?(:lab_1_report)
          patient_details[:lab_1_result] = patients_labs[patient.id][:first][:result] || '' if fields.include?(:lab_1_result)
        end
        if patients_labs[patient.id].key?(:second)
          patient_details[:lab_2_type] = patients_labs[patient.id][:first][:lab_type] || '' if fields.include?(:lab_2_type)
          if fields.include?(:lab_2_specimen_collection)
            patient_details[:lab_2_specimen_collection] = patients_labs[patient.id][:first][:specimen_collection]&.strftime('%F') || ''
          end
          patient_details[:lab_2_report] = patients_labs[patient.id][:first][:report]&.strftime('%F') || '' if fields.include?(:lab_2_report)
          patient_details[:lab_2_result] = patients_labs[patient.id][:first][:result] || '' if fields.include?(:lab_2_result)
        end
      end

      patients_details << patient_details
    end

    patients_details
  end

  def extract_incomplete_patient_details(patient, fields)
    details = {}
    number_fields = %i[id assigned_user]
    string_fields = %i[first_name middle_name last_name sex ethnicity primary_language secondary_language nationality user_defined_id_statelocal
                       user_defined_id_cdc user_defined_id_nndss address_line_1 address_city address_state address_line_2 address_zip address_county
                       foreign_address_line_1 foreign_address_city foreign_address_country foreign_address_line_2 foreign_address_zip foreign_address_line_3
                       foreign_address_state monitored_address_line_1 monitored_address_city monitoring_address_state monitored_address_state
                       monitored_address_line_2 monitored_address_zip monitored_address_county foreign_monitored_address_line_1 foreign_monitored_address_city
                       foreign_monitored_address_state foreign_monitored_address_line_2 foreign_monitored_address_zip foreign_monitored_address_county
                       preferred_contact_method primary_telephone primary_telephone_type secondary_telephone secondary_telephone_type preferred_contact_time
                       email port_of_origin source_of_report flight_or_vessel_number flight_or_vessel_carrier port_of_entry_into_usa travel_related_notes
                       additional_planned_travel_type additional_planned_travel_destination additional_planned_travel_destination_state
                       additional_planned_travel_destination_country additional_planned_travel_port_of_departure additional_planned_travel_related_notes
                       potential_exposure_country potential_exposure_country contact_of_known_case_id was_in_health_care_facility_with_known_cases_facility_name
                       laboratory_personnel_facility_name healthcare_personnel_facility_name member_of_a_common_exposure_cohort_type exposure_risk_assessment
                       monitoring_plan exposure_notes case_status gender_identity sexual_orientation risk_level monitoring_reason public_health_action]
    date_fields = %i[date_of_birth date_of_departure date_of_arrival additional_planned_travel_start_date additional_planned_travel_end_date
                     last_date_of_exposure symptom_onset extended_isolation]
    bool_fields = %i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander interpretation_required
                     contact_of_known_case travel_to_affected_country_or_area was_in_health_care_facility_with_known_cases laboratory_personnel
                     healthcare_personnel crew_on_passenger_or_cargo_flight member_of_a_common_exposure_cohort]

    (number_fields + string_fields).each do |field|
      details[field] = patient[field] || '' if fields.include?(field)
    end

    date_fields.each do |field|
      details[field] = patient[field]&.strftime('%F') || '' if fields.include?(field)
    end

    bool_fields.each do |field|
      details[field] = patient[field] || false if fields.include?(field)
    end

    details
  end

  def csv_line_list(patients)
    package = CSV.generate(headers: true) do |csv|
      csv << LINELIST_HEADERS
      patient_statuses = statuses(patients)
      patients.find_in_batches(batch_size: 500) do |patients_group|
        linelists = linelists_for_export(patients_group, patient_statuses)
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
        patient_statuses = statuses(patients)
        patients.find_in_batches(batch_size: 500) do |patients_group|
          comprehensive_details = comprehensive_details_for_export(patients_group, patient_statuses)
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
        patient_statuses = statuses(patients)
        patients.find_in_batches(batch_size: 500) do |patients_group|
          comprehensive_details = comprehensive_details_for_export(patients_group, patient_statuses)
          patients_group.each do |patient|
            extended_isolation = patient[:extended_isolation]&.strftime('%F') || ''
            values = [patient.id] + comprehensive_details[patient.id].values + [extended_isolation]
            sheet.add_row values, { types: Array.new(MONITOREES_LIST_HEADERS.length + 2, :string) }
          end
        end
      end
      p.workbook.add_worksheet(name: 'Reports') do |sheet|
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
        patient_statuses = statuses(patients)
        patients.find_in_batches(batch_size: 500) do |patients_group|
          comprehensive_details = comprehensive_details_for_export(patients_group, patient_statuses)
          patients_group.each do |patient|
            extended_isolation = patient[:extended_isolation]&.strftime('%F') || ''
            values = [patient.id] + comprehensive_details[patient.id].values + [extended_isolation]
            sheet.add_row values, { types: Array.new(MONITOREES_LIST_HEADERS.length + 2, :string) }
          end
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  def excel_export_assessments(patients)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: 'Reports') do |sheet|
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
  def linelists_for_export(patients, patient_statuses)
    linelists = incomplete_linelists_for_export(patients)
    patients_jurisdiction_names = jurisdiction_names(patients)
    patients_transfers = transfers(patients)
    patients.each do |patient|
      linelists[patient.id][:jurisdiction] = patients_jurisdiction_names[patient.id]
      linelists[patient.id][:status] = patient_statuses[patient.id]&.gsub('exposure ', '')&.gsub('isolation ', '')
      next unless patients_transfers[patient.id]

      %i[transferred_at transferred_from transferred_to].each do |transfer_field|
        linelists[patient.id][transfer_field] = patients_transfers[patient.id][transfer_field]
      end
    end
    linelists
  end

  # Patient fields relevant to sara alert format and excel export
  def comprehensive_details_for_export(patients, patient_statuses)
    comprehensive_details = incomplete_comprehensive_details_for_export(patients)
    patients_jurisdiction_paths = jurisdiction_paths(patients)
    patients_labs = laboratories(patients)
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

  # Status of each patient (faster to do this in bulk than individually for exports)
  def statuses(patients)
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
    patient_statuses = {}
    tabs.each do |tab, patient_ids|
      patient_ids.each do |patient_id|
        patient_statuses[patient_id] = tab&.to_s&.humanize&.downcase
      end
    end
    patient_statuses
  end

  # Latest transfer of each patient
  def transfers(patients)
    transfers = patients.pluck(:id, :latest_transfer_at)
    transfers = Transfer.where(patient_id: transfers.map { |lt| lt[0] }, created_at: transfers.map { |lt| lt[1] })
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
  def laboratories(patients)
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
        expected_purge_date: patient[:updated_at].nil? ? '' : ((patient[:updated_at] + ADMIN_OPTIONS['purgeable_after'].minutes)&.rfc2822 || ''),
        symptom_onset: patient[:symptom_onset]&.strftime('%F') || '',
        extended_isolation: patient[:extended_isolation]&.strftime('%F') || ''
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
