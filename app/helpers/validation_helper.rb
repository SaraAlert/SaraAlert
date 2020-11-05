# frozen_string_literal: true

module ValidationHelper # rubocop:todo Metrics/ModuleLength
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
    case_status: ['Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case'],
    lab_type: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other'],
    result: %w[positive negative indeterminate other],
    sex: %w[Male Female Unknown],
    address_state: VALID_STATES,
    monitored_address_state: VALID_STATES
  }.freeze

  VALID_EXPOSURE_ENUMS = {
    case_status: ['Suspect', 'Unknown', 'Not a Case']
  }.freeze

  VALID_ISOLATION_ENUMS = {
    case_status: %w[Confirmed Probable]
  }.freeze

  NORMALIZED_ENUMS = VALID_ENUMS.transform_values do |values|
    Hash[values.collect { |value| [value.to_s.downcase.gsub(/[ -.]/, ''), value] }]
  end

  NORMALIZED_EXPOSURE_ENUMS = VALID_EXPOSURE_ENUMS.transform_values do |values|
    Hash[values.collect { |value| [value.to_s.downcase.gsub(/[ -.]/, ''), value] }]
  end

  NORMALIZED_ISOLATION_ENUMS = VALID_ISOLATION_ENUMS.transform_values do |values|
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
    address_line_1: { label: 'Address 1', checks: [:required] },
    address_city: { label: 'Town/City', checks: [:required] },
    address_zip: { label: 'Zip', checks: [:required] },
    address_state: { label: 'State', checks: %i[required state] },
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
    lab_type: { label: 'Lab Test Type', checks: [:enum] },
    specimen_collection: { label: 'Lab Specimen Collection Date', checks: [:date] },
    report: { label: 'Lab Report Date', checks: [:date] },
    result: { label: 'Result', check: [:enum] }
  }.freeze
end
