# frozen_string_literal: true

# Constants for imports and exports
module ImportExportConstants # rubocop:todo Metrics/ModuleLength
  EXPORT_TYPES = {
    csv_linelist_exposure: { label: 'Line list CSV (exposure)', filename: 'Sara-Alert-Linelist-Exposure' },
    csv_linelist_isolation: { label: 'Line list CSV (isolation)', filename: 'Sara-Alert-Linelist-Isolation' },
    sara_alert_format_exposure: { label: 'Sara Alert Format (exposure)', filename: 'Sara-Alert-Format-Exposure' },
    sara_alert_format_isolation: { label: 'Sara Alert Format (isolation)', filename: 'Sara-Alert-Format-Isolation' },
    full_history_patients_all: { label: 'Excel Export For All Monitorees', filename: 'Sara-Alert-Full-Export' },
    full_history_patients_purgeable: { label: 'Excel Export For Purge-Eligible Monitorees', filename: 'Sara-Alert-Purge-Eligible-Export' },
    custom: { label: 'Custom Export', filename: 'Sara-Alert-Custom-Export' }
  }.freeze

  EXPORT_FORMATS = %w[csv xlsx].freeze

  EPI_X_FIELDS = [:user_defined_id_statelocal, :flight_or_vessel_number, nil, nil, :user_defined_id_cdc, nil, nil, :primary_language, :date_of_arrival,
                  :port_of_entry_into_usa, :last_name, :first_name, :date_of_birth, :sex, nil, nil, :address_line_1, :address_city, :address_state,
                  :address_zip, :monitored_address_line_1, :monitored_address_city, :monitored_address_state, :monitored_address_zip, nil, nil, nil, nil,
                  :primary_telephone, :secondary_telephone, :email, nil, nil, nil, :potential_exposure_location, :potential_exposure_country,
                  :date_of_departure, nil, nil, nil, nil, :contact_of_known_case, :was_in_health_care_facility_with_known_cases].freeze

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

  LINELIST_FIELDS = %i[id name jurisdiction_name assigned_user user_defined_id_statelocal sex date_of_birth end_of_monitoring exposure_risk_assessment
                       monitoring_plan latest_assessment_at latest_transfer_at monitoring_reason public_health_action status closed_at transferred_from
                       transferred_to expected_purge_ts symptom_onset extended_isolation].freeze

  LINELIST_HEADERS = ['Patient ID', 'Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level',
                      'Monitoring Plan', 'Latest Report', 'Transferred At', 'Reason For Closure', 'Latest Public Health Action', 'Status', 'Closed At',
                      'Transferred From', 'Transferred To', 'Expected Purge Date', 'Symptom Onset', 'Extended Isolation'].freeze

  SARA_ALERT_FORMAT_FIELDS = %i[first_name middle_name last_name date_of_birth sex white black_or_african_american american_indian_or_alaska_native asian
                                native_hawaiian_or_other_pacific_islander ethnicity primary_language secondary_language interpretation_required nationality
                                user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss address_line_1 address_city address_state address_line_2
                                address_zip address_county foreign_address_line_1 foreign_address_city foreign_address_country foreign_address_line_2
                                foreign_address_zip foreign_address_line_3 foreign_address_state monitored_address_line_1 monitored_address_city
                                monitored_address_state monitored_address_line_2 monitored_address_zip monitored_address_county foreign_monitored_address_line_1
                                foreign_monitored_address_city foreign_monitored_address_state foreign_monitored_address_line_2 foreign_monitored_address_zip
                                foreign_monitored_address_county preferred_contact_method primary_telephone primary_telephone_type secondary_telephone
                                secondary_telephone_type preferred_contact_time email port_of_origin date_of_departure source_of_report flight_or_vessel_number
                                flight_or_vessel_carrier port_of_entry_into_usa date_of_arrival travel_related_notes additional_planned_travel_type
                                additional_planned_travel_destination additional_planned_travel_destination_state additional_planned_travel_destination_country
                                additional_planned_travel_port_of_departure additional_planned_travel_start_date additional_planned_travel_end_date
                                additional_planned_travel_related_notes last_date_of_exposure potential_exposure_location potential_exposure_country
                                contact_of_known_case contact_of_known_case_id travel_to_affected_country_or_area was_in_health_care_facility_with_known_cases
                                was_in_health_care_facility_with_known_cases_facility_name laboratory_personnel laboratory_personnel_facility_name
                                healthcare_personnel healthcare_personnel_facility_name crew_on_passenger_or_cargo_flight member_of_a_common_exposure_cohort
                                member_of_a_common_exposure_cohort_type exposure_risk_assessment monitoring_plan exposure_notes full_status symptom_onset
                                case_status lab_1_type lab_1_specimen_collection lab_1_report lab_1_result lab_2_type lab_2_specimen_collection lab_2_report
                                lab_2_result jurisdiction_path assigned_user gender_identity sexual_orientation race_other race_unknown
                                race_refused_to_answer].freeze

  SARA_ALERT_FORMAT_HEADERS = ['First Name', 'Middle Name', 'Last Name', 'Date of Birth', 'Sex at Birth', 'White', 'Black or African American',
                               'American Indian or Alaska Native', 'Asian', 'Native Hawaiian or Other Pacific Islander', 'Ethnicity', 'Primary Language',
                               'Secondary Language', 'Interpretation Required?', 'Nationality', 'Identifier (STATE/LOCAL)', 'Identifier (CDC)',
                               'Identifier (NNDSS)', 'Address Line 1', 'Address City', 'Address State', 'Address Line 2', 'Address Zip', 'Address County',
                               'Foreign Address Line 1', 'Foreign Address City', 'Foreign Address Country', 'Foreign Address Line 2', 'Foreign Address Zip',
                               'Foreign Address Line 3', 'Foreign Address State', 'Monitored Address Line 1', 'Monitored Address City',
                               'Monitored Address State', 'Monitored Address Line 2', 'Monitored Address Zip', 'Monitored Address County',
                               'Foreign Monitored Address Line 1', 'Foreign Monitored Address City', 'Foreign Monitored Address State',
                               'Foreign Monitored Address Line 2', 'Foreign Monitored Address Zip', 'Foreign Monitored Address County',
                               'Preferred Contact Method', 'Primary Telephone', 'Primary Telephone Type', 'Secondary Telephone', 'Secondary Telephone Type',
                               'Preferred Contact Time', 'Email', 'Port of Origin', 'Date of Departure', 'Source of Report', 'Flight or Vessel Number',
                               'Flight or Vessel Carrier', 'Port of Entry Into USA', 'Date of Arrival', 'Travel Related Notes',
                               'Additional Planned Travel Type', 'Additional Planned Travel Destination', 'Additional Planned Travel Destination State',
                               'Additional Planned Travel Destination Country', 'Additional Planned Travel Port of Departure',
                               'Additional Planned Travel Start Date', 'Additional Planned Travel End Date', 'Additional Planned Travel Related Notes',
                               'Last Date of Exposure', 'Potential Exposure Location', 'Potential Exposure Country', 'Contact of Known Case?',
                               'Contact of Known Case ID', 'Travel from Affected Country or Area?', 'Was in Health Care Facility With Known Cases?',
                               'Health Care Facility with Known Cases Name', 'Laboratory Personnel?', 'Laboratory Personnel Facility Name',
                               'Health Care Personnel?', 'Health Care Personnel Facility Name', 'Crew on Passenger or Cargo Flight?',
                               'Member of a Common Exposure Cohort?', 'Common Exposure Cohort Name', 'Exposure Risk Assessment', 'Monitoring Plan',
                               'Exposure Notes', 'Status', 'Symptom Onset Date', 'Case Status', 'Lab 1 Test Type', 'Lab 1 Specimen Collection Date',
                               'Lab 1 Report Date', 'Lab 1 Result', 'Lab 2 Test Type', 'Lab 2 Specimen Collection Date', 'Lab 2 Report Date', 'Lab 2 Result',
                               'Full Assigned Jurisdiction Path', 'Assigned User', 'Gender Identity', 'Sexual Orientation', 'Race Other', 'Race Unknown',
                               'Race Refused to Answer'].freeze

  # Extended Isolation Date is intentionally appended to the end even if new fields are added to Sara Alert Format to maintain more consistency in the ordering
  # of fields between Sara Alert Format and Full History Patients
  FULL_HISTORY_PATIENTS_FIELDS = ([:id] + SARA_ALERT_FORMAT_FIELDS + [:extended_isolation]).freeze

  FULL_HISTORY_PATIENTS_HEADERS = (['Patient ID'] + SARA_ALERT_FORMAT_HEADERS + ['Extended Isolation Date']).freeze

  FULL_HISTORY_ASSESSMENTS_FIELDS = %i[patient_id symptomatic who_reported created_at updated_at symptoms].freeze

  FULL_HISTORY_ASSESSMENTS_HEADERS = ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At', 'Symptoms Reported'].freeze

  FULL_HISTORY_LABORATORIES_FIELDS = %i[patient_id lab_type specimen_collection report result created_at updated_at].freeze

  FULL_HISTORY_LABORATORIES_HEADERS = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result', 'Created At', 'Updated At'].freeze

  FULL_HISTORY_VACCINES_FIELDS = %i[patient_id group_name product_name administration_date dose_number notes created_at updated_at].freeze

  FULL_HISTORY_VACCINES_HEADERS = ['Patient ID', 'Vaccine Group', 'Product Name', 'Administration Date', 'Dose Number', 'Notes', 'Created At',
                                   'Updated At'].freeze

  FULL_HISTORY_HISTORIES_FIELDS = %i[patient_id comment created_by history_type created_at updated_at].freeze

  FULL_HISTORY_HISTORIES_HEADERS = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At'].freeze

  PATIENT_FIELD_TYPES = {
    numbers: %i[id assigned_user responder_id],
    strings: %i[first_name middle_name last_name sex ethnicity primary_language secondary_language nationality user_defined_id_statelocal user_defined_id_cdc
                user_defined_id_nndss address_line_1 address_city address_state address_line_2 address_zip address_county foreign_address_line_1
                foreign_address_city foreign_address_country foreign_address_line_2 foreign_address_zip foreign_address_line_3 foreign_address_state
                monitored_address_line_1 monitored_address_city monitoring_address_state monitored_address_state monitored_address_line_2 monitored_address_zip
                monitored_address_county foreign_monitored_address_line_1 foreign_monitored_address_city foreign_monitored_address_state
                foreign_monitored_address_line_2 foreign_monitored_address_zip foreign_monitored_address_county preferred_contact_method primary_telephone_type
                secondary_telephone_type preferred_contact_time email port_of_origin source_of_report source_of_report_specify flight_or_vessel_number
                flight_or_vessel_carrier port_of_entry_into_usa travel_related_notes additional_planned_travel_type additional_planned_travel_destination
                additional_planned_travel_destination_state additional_planned_travel_destination_country additional_planned_travel_port_of_departure
                additional_planned_travel_related_notes potential_exposure_location potential_exposure_country contact_of_known_case_id
                was_in_health_care_facility_with_known_cases_facility_name laboratory_personnel_facility_name healthcare_personnel_facility_name
                member_of_a_common_exposure_cohort_type exposure_risk_assessment monitoring_plan exposure_notes case_status gender_identity
                sexual_orientation risk_level monitoring_reason public_health_action],
    dates: %i[date_of_birth date_of_departure date_of_arrival additional_planned_travel_start_date additional_planned_travel_end_date last_date_of_exposure
              symptom_onset extended_isolation],
    timestamps: %i[created_at updated_at closed_at latest_assessment_at latest_transfer_at last_assessment_reminder_sent],
    phones: %i[primary_telephone secondary_telephone],
    booleans: %i[interpretation_required isolation continuous_exposure contact_of_known_case travel_to_affected_country_or_area
                 was_in_health_care_facility_with_known_cases laboratory_personnel healthcare_personnel crew_on_passenger_or_cargo_flight
                 member_of_a_common_exposure_cohort head_of_household pause_notifications],
    races: %i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander race_other race_unknown
              race_refused_to_answer],
    alternative_identifiers: %i[user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss],
    lab_fields: %i[lab_1_type lab_1_specimen_collection lab_1_report lab_1_result lab_2_type lab_2_specimen_collection lab_2_report lab_2_result]
  }.freeze

  PATIENT_FIELD_NAMES = {
    # Enrollment Info - Identification and Demographics - Identifiers
    id: 'Sara Alert ID',
    user_defined_id_statelocal: 'State/Local ID',
    user_defined_id_cdc: 'CDC ID',
    user_defined_id_nndss: 'NNDSS ID',
    # Enrollment Info - Identification and Demographics - Name
    first_name: 'First Name',
    last_name: 'Last Name',
    middle_name: 'Middle Name',
    # Enrollment Info - Identification and Demographics - Date of Birth
    date_of_birth: 'Date of Birth',
    age: 'Age',
    # Enrollment Info - Identification and Demographics - Sex at Birth
    sex: 'Sex at Birth',
    # Enrollment Info - Identification and Demographics - Gender Identity and Sexual Orientation
    gender_identity: 'Gender Identity',
    sexual_orientation: 'Sexual Orientation',
    # Enrollment Info - Identification and Demographics - Race, Ethnicity, and Nationality
    race: 'Race (All Race Fields)',
    white: 'White',
    black_or_african_american: 'Black or African American',
    american_indian_or_alaska_native: 'American Indian or Alaska Native',
    asian: 'Asian',
    native_hawaiian_or_other_pacific_islander: 'Native Hawaiian or Other Pacific Islander',
    race_other: 'Race Other',
    race_unknown: 'Race Unknown',
    race_refused_to_answer: 'Race Refused to Answer',
    ethnicity: 'Ethnicity',
    nationality: 'Nationality',
    # Enrollment Info - Identification and Demographics - Language
    primary_language: 'Primary Language',
    secondary_language: 'Secondary Language',
    interpretation_required: 'Interpretation Required',
    # Enrollment Info - Home and Monitored Address - Home Address (USA)
    address_line_1: 'Address Line 1',
    address_line_2: 'Address Line 2',
    address_city: 'Address City',
    address_state: 'Address State',
    address_zip: 'Address Zip',
    address_county: 'Address County',
    # Enrollment Info - Home and Monitored Address - Home Address (Foreign)
    foreign_address_line_1: 'Foreign Address Line 1',
    foreign_address_line_2: 'Foreign Address Line 2',
    foreign_address_city: 'Foreign Address City',
    foreign_address_country: 'Foreign Address Country',
    foreign_address_zip: 'Foreign Address Zip',
    foreign_address_line_3: 'Foreign Address Line 3',
    foreign_address_state: 'Foreign Address State',
    # Enrollment Info - Home and Monitored Address - Monitored Address (USA)
    monitored_address_line_1: 'Monitored Address Line 1',
    monitored_address_line_2: 'Monitored Address Line 2',
    monitored_address_city: 'Monitored Address City',
    monitored_address_state: 'Monitored Address State',
    monitored_address_zip: 'Monitored Address Zip',
    monitored_address_county: 'Monitored Address County',
    # Enrollment Info - Home and Monitored Address - Monitored Address (Foreign)
    foreign_monitored_address_line_1: 'Foreign Monitored Address Line 1',
    foreign_monitored_address_line_2: 'Foreign Monitored Address Line 2',
    foreign_monitored_address_city: 'Foreign Monitored Address City',
    foreign_monitored_address_state: 'Foreign Monitored Address State',
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
    # Enrollment Info - Travel - Arrival Information
    port_of_origin: 'Port of Origin',
    date_of_departure: 'Date of Departure',
    flight_or_vessel_number: 'Flight or Vessel Number',
    flight_or_vessel_carrier: 'Flight or Vessel Carrier',
    port_of_entry_into_usa: 'Port of Entry Into USA',
    date_of_arrival: 'Date of Arrival',
    source_of_report: 'Source of Report',
    source_of_report_specify: 'Source of Report Specify',
    travel_related_notes: 'Travel Related Notes',
    # Enrollment Info - Travel - Additional Planned Travel
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
    # Enrollment Info - Potential Exposure Information - Risk Factors
    contact_of_known_case: 'Contact of Known Case',
    contact_of_known_case_id: 'Contact of Known Case ID',
    travel_to_affected_country_or_area: 'Travel from Affected Country or Area',
    was_in_health_care_facility_with_known_cases: 'Was in Health Care Facility With Known Cases',
    was_in_health_care_facility_with_known_cases_facility_name: 'Health Care Facility with Known Cases Name',
    laboratory_personnel: 'Laboratory Personnel',
    laboratory_personnel_facility_name: 'Laboratory Personnel Facility Name',
    healthcare_personnel: 'Health Care Personnel',
    healthcare_personnel_facility_name: 'Health Care Personnel Facility Name',
    crew_on_passenger_or_cargo_flight: 'Crew on Passenger or Cargo Flight',
    member_of_a_common_exposure_cohort: 'Member of a Common Exposure Cohort',
    member_of_a_common_exposure_cohort_type: 'Common Exposure Cohort Name',
    exposure_notes: 'Exposure Notes',
    # Enrollment Info - Record Creation and Updates
    creator: 'Enroller',
    created_at: 'Monitoree Created Date',
    updated_at: 'Monitoree Updated Date',
    # Monitoring Info - Linelist Info
    workflow: 'Current Workflow',
    status: 'Status',
    # Monitoring Info - Monitoring Actions
    monitoring_status: 'Monitoring Status',
    exposure_risk_assessment: 'Exposure Risk Assessment',
    monitoring_plan: 'Monitoring Plan',
    case_status: 'Case Status',
    public_health_action: 'Latest Public Health Action',
    jurisdiction_path: 'Full Assigned Jurisdiction Path',
    jurisdiction_name: 'Assigned Jurisdiction',
    assigned_user: 'Assigned User',
    # Monitoring Info - Monitoring Period
    last_date_of_exposure: 'Last Date of Exposure',
    continuous_exposure: 'Continuous Exposure',
    symptom_onset: 'Symptom Onset Date',
    symptom_onset_defined_by: 'Symptom Onset Defined By',
    no_symptom_history: 'No Symptom History',
    extended_isolation: 'Extended Isolation Date',
    end_of_monitoring: 'End of Monitoring',
    closed_at: 'Closure Date',
    monitoring_reason: 'Reason For Closure',
    expected_purge_ts: 'Expected Purge Date',
    # Monitoring Info - Reporting Info
    responder_id: 'ID of Reporter',
    head_of_household: 'Head of Household',
    pause_notifications: 'Paused Notifications',
    last_assessment_reminder_sent: 'Last Assessment Reminder Sent Date',
    # CSV Linelist Export Specific Fields
    name: 'Name',
    latest_assessment_at: 'Latest Report',
    latest_transfer_at: 'Transferred At',
    transferred_from: 'Transferred From',
    transferred_to: 'Transferred To'
  }.freeze

  ASSESSMENT_FIELD_NAMES = {
    patient_id: 'Sara Alert ID',
    user_defined_id_statelocal: 'State/Local ID',
    user_defined_id_cdc: 'CDC ID',
    user_defined_id_nndss: 'NNDSS ID',
    id: 'Report ID',
    symptomatic: 'Needs Review',
    who_reported: 'Who Reported',
    created_at: 'Report Created Date',
    updated_at: 'Report Updated Date',
    symptoms: 'Symptoms Reported'
  }.freeze

  LABORATORY_FIELD_NAMES = {
    patient_id: 'Sara Alert ID',
    user_defined_id_statelocal: 'State/Local ID',
    user_defined_id_cdc: 'CDC ID',
    user_defined_id_nndss: 'NNDSS ID',
    id: 'Lab Report ID',
    lab_type: 'Lab Type',
    specimen_collection: 'Specimen Collection Date',
    report: 'Report Date',
    result: 'Lab Result',
    created_at: 'Lab Report Created Date',
    updated_at: 'Lab Report Updated Date'
  }.freeze

  VACCINE_FIELD_NAMES = {
    patient_id: 'Sara Alert ID',
    user_defined_id_statelocal: 'State/Local ID',
    user_defined_id_cdc: 'CDC ID',
    user_defined_id_nndss: 'NNDSS ID',
    id: 'Vaccination ID',
    group_name: 'Vaccine Group',
    product_name: 'Product Name',
    administration_date: 'Administration Date',
    dose_number: 'Dose Number',
    notes: 'Notes',
    created_at: 'Vaccination Created Date',
    updated_at: 'Vaccination Updated Date'
  }.freeze

  CLOSE_CONTACT_FIELD_NAMES = {
    patient_id: 'Sara Alert ID',
    user_defined_id_statelocal: 'State/Local ID',
    user_defined_id_cdc: 'CDC ID',
    user_defined_id_nndss: 'NNDSS ID',
    id: 'Close Contact ID',
    first_name: 'First Name',
    last_name: 'Last Name',
    primary_telephone: 'Primary Telephone',
    email: 'Email',
    contact_attempts: 'Contact Attempts',
    last_date_of_exposure: 'Last Date of Exposure',
    assigned_user: 'Assigned User',
    notes: 'Notes',
    enrolled_id: 'Enrolled ID',
    created_at: 'Close Contact Created Date',
    updated_at: 'Close Contact Updated Date'
  }.freeze

  TRANSFER_FIELD_NAMES = {
    patient_id: 'Sara Alert ID',
    user_defined_id_statelocal: 'State/Local ID',
    user_defined_id_cdc: 'CDC ID',
    user_defined_id_nndss: 'NNDSS ID',
    id: 'Transfer ID',
    who: 'Who Initiated Transfer',
    from_jurisdiction: 'From Jurisdiction',
    to_jurisdiction: 'To Jurisdiction',
    created_at: 'Transfer Created Date',
    updated_at: 'Transfer Updated Date'
  }.freeze

  HISTORY_FIELD_NAMES = {
    patient_id: 'Sara Alert ID',
    user_defined_id_statelocal: 'State/Local ID',
    user_defined_id_cdc: 'CDC ID',
    user_defined_id_nndss: 'NNDSS ID',
    id: 'History ID',
    created_by: 'History Creator',
    history_type: 'History Type',
    comment: 'History Comment',
    created_at: 'History Created Date',
    updated_at: 'History Updated Date'
  }.freeze

  ALL_FIELDS_NAMES = {
    patients: PATIENT_FIELD_NAMES,
    assessments: ASSESSMENT_FIELD_NAMES,
    laboratories: LABORATORY_FIELD_NAMES,
    vaccines: VACCINE_FIELD_NAMES,
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
    label: 'Monitorees',
    nodes: [
      {
        value: 'patients',
        label: 'Monitoree Details',
        children: [
          {
            value: 'patients-enrollment',
            label: 'Enrollment Info',
            children: [
              {
                value: 'patients-enrollment-identification-and-demographics',
                label: 'Identification and Demographics',
                children: [
                  rct_node(:patients, 'Identifiers', %i[id user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss]),
                  rct_node(:patients, 'Name', %i[first_name last_name middle_name]),
                  rct_node(:patients, 'Date of Birth', %i[date_of_birth age]),
                  { value: :sex, label: ALL_FIELDS_NAMES[:patients][:sex] },
                  rct_node(:patients, 'Gender Identity and Sexual Orientation', %i[gender_identity sexual_orientation]),
                  rct_node(:patients, 'Race, Ethnicity, and Nationality', %i[race ethnicity nationality]),
                  rct_node(:patients, 'Language', %i[primary_language secondary_language interpretation_required])
                ]
              },
              {
                value: 'patients-enrollment-home-and-monitored-address',
                label: 'Home and Monitored Address',
                children: [
                  rct_node(:patients, 'Home Address (USA)', %i[address_line_1 address_line_2 address_city address_state address_zip address_county]),
                  rct_node(:patients, 'Home Address (Foreign)', %i[foreign_address_line_1 foreign_address_line_2 foreign_address_city foreign_address_country
                                                                   foreign_address_zip foreign_address_line_3 foreign_address_state]),
                  rct_node(:patients, 'Monitored Address (USA)', %i[monitored_address_line_1 monitored_address_line_2 monitored_address_city
                                                                    monitored_address_state monitored_address_zip monitored_address_county]),
                  rct_node(:patients, 'Monitored Address (Foreign)', %i[foreign_monitored_address_line_1 foreign_monitored_address_line_2
                                                                        foreign_monitored_address_city foreign_monitored_address_state
                                                                        foreign_monitored_address_zip foreign_monitored_address_county])
                ]
              },
              rct_node(:patients, 'Contact Information', %i[preferred_contact_method preferred_contact_time primary_telephone primary_telephone_type
                                                            secondary_telephone secondary_telephone_type email]),
              {
                value: 'patients-enrollment-travel',
                label: 'Travel',
                children: [
                  rct_node(:patients, 'Arrival Information', %i[port_of_origin date_of_departure flight_or_vessel_number flight_or_vessel_carrier
                                                                port_of_entry_into_usa date_of_arrival source_of_report source_of_report_specify
                                                                travel_related_notes]),
                  rct_node(:patients, 'Additional Planned Travel', %i[additional_planned_travel_type additional_planned_travel_destination
                                                                      additional_planned_travel_destination_state additional_planned_travel_destination_country
                                                                      additional_planned_travel_port_of_departure additional_planned_travel_start_date
                                                                      additional_planned_travel_end_date additional_planned_travel_related_notes])
                ]
              },
              {
                value: 'patients-enrollment-potential_exposure_information',
                label: 'Potential Exposure Information',
                children: [
                  rct_node(:patients, 'Exposure Location and Notes', %i[potential_exposure_location potential_exposure_country]),
                  rct_node(:patients, 'Exposure Risk Factors', %i[contact_of_known_case contact_of_known_case_id travel_to_affected_country_or_area
                                                                  was_in_health_care_facility_with_known_cases
                                                                  was_in_health_care_facility_with_known_cases_facility_name laboratory_personnel
                                                                  laboratory_personnel_facility_name healthcare_personnel healthcare_personnel_facility_name
                                                                  crew_on_passenger_or_cargo_flight member_of_a_common_exposure_cohort
                                                                  member_of_a_common_exposure_cohort_type exposure_notes])
                ]
              },
              rct_node(:patients, 'Record Creation and Updates', %i[creator created_at updated_at])
            ]
          },
          {
            value: 'patients-monitoring',
            label: 'Monitoring Info',
            children: [
              rct_node(:patients, 'Linelist Info', %i[workflow status]),
              rct_node(:patients, 'Monitoring Actions', %i[monitoring_status exposure_risk_assessment monitoring_plan case_status public_health_action
                                                           jurisdiction_path jurisdiction_name assigned_user]),
              rct_node(:patients, 'Monitoring Period', %i[last_date_of_exposure continuous_exposure symptom_onset symptom_onset_defined_by no_symptom_history
                                                          extended_isolation end_of_monitoring closed_at monitoring_reason expected_purge_ts]),
              rct_node(:patients, 'Reporting Info', %i[responder_id head_of_household pause_notifications last_assessment_reminder_sent])
            ]
          }
        ]
      }
    ]
  }.freeze

  ASSESSMENTS_EXPORT_OPTIONS = {
    label: 'Reports',
    nodes: [rct_node(:assessments, 'Reports', %i[patient_id user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss id symptomatic
                                                 who_reported created_at updated_at symptoms])]
  }.freeze

  LABORATORIES_EXPORT_OPTIONS = {
    label: 'Lab Results',
    nodes: [rct_node(:laboratories, 'Lab Results', %i[patient_id user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss id lab_type
                                                      specimen_collection report result created_at updated_at])]
  }.freeze

  VACCINES_EXPORT_OPTIONS = {
    label: 'Vaccinations',
    nodes: [rct_node(:vaccines, 'Vaccinations', %i[patient_id user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss id group_name
                                                   product_name administration_date dose_number notes created_at updated_at])]
  }.freeze

  CLOSE_CONTACTS_EXPORT_OPTIONS = {
    label: 'Close Contacts',
    nodes: [rct_node(:close_contacts, 'Close Contacts', %i[patient_id user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss id first_name
                                                           last_name primary_telephone email contact_attempts last_date_of_exposure assigned_user notes
                                                           enrolled_id created_at updated_at])]
  }.freeze

  TRANSFERS_EXPORT_OPTIONS = {
    label: 'Transfers',
    nodes: [rct_node(:transfers, 'Transfers', %i[patient_id user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss id who from_jurisdiction
                                                 to_jurisdiction created_at updated_at])]
  }.freeze

  HISTORIES_EXPORT_OPTIONS = {
    label: 'Histories',
    nodes: [rct_node(:histories, 'History', %i[patient_id user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss id created_by history_type
                                               comment created_at updated_at])]
  }.freeze

  CUSTOM_EXPORT_OPTIONS = {
    patients: PATIENTS_EXPORT_OPTIONS,
    assessments: ASSESSMENTS_EXPORT_OPTIONS,
    laboratories: LABORATORIES_EXPORT_OPTIONS,
    vaccines: VACCINES_EXPORT_OPTIONS,
    close_contacts: CLOSE_CONTACTS_EXPORT_OPTIONS,
    transfers: TRANSFERS_EXPORT_OPTIONS,
    histories: HISTORIES_EXPORT_OPTIONS
  }.freeze

  FULL_HISTORY_PATIENT_CONFIG = {
    format: 'xlsx',
    separate_files: false,
    data: {
      patients: {
        checked: FULL_HISTORY_PATIENTS_FIELDS,
        headers: FULL_HISTORY_PATIENTS_HEADERS,
        tab: 'Monitorees List'
      },
      assessments: {
        checked: FULL_HISTORY_ASSESSMENTS_FIELDS,
        headers: FULL_HISTORY_ASSESSMENTS_HEADERS,
        tab: 'Reports'
      },
      laboratories: {
        checked: FULL_HISTORY_LABORATORIES_FIELDS,
        headers: FULL_HISTORY_LABORATORIES_HEADERS,
        tab: 'Lab Results'
      },
      vaccines: {
        checked: FULL_HISTORY_VACCINES_FIELDS,
        headers: FULL_HISTORY_VACCINES_HEADERS,
        tab: 'Vaccinations'
      },
      histories: {
        checked: FULL_HISTORY_HISTORIES_FIELDS,
        headers: FULL_HISTORY_HISTORIES_HEADERS,
        tab: 'Edit Histories'
      }
    }
  }.freeze
end
