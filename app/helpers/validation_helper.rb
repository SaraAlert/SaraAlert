# frozen_string_literal: true

# ValidationHelper: Helper constants and methods for validation.
module ValidationHelper # rubocop:todo Metrics/ModuleLength
  SEX_ABBREVIATIONS = {
    M: 'Male',
    F: 'Female',
    U: 'Unknown',
    UNREPORTED: 'Unknown'
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

  USER_SELECTABLE_MONITORING_REASONS = [
    'Completed Monitoring',
    'Meets criteria to shorten quarantine',
    'Does not meet criteria for monitoring',
    'Meets Case Definition',
    'Lost to follow-up during monitoring period',
    'Lost to follow-up (contact never established)',
    'Transferred to another jurisdiction',
    'Person Under Investigation (PUI)',
    'Case confirmed',
    'Past monitoring period',
    'Meets criteria to discontinue isolation',
    'Fully Vaccinated',
    'Deceased',
    'Duplicate',
    'Other'
  ].freeze

  # Please note, this array is only used for the demo.rake file.
  # The FollowUpFlag component's flag reasons are populated in-line.
  FOLLOW_UP_FLAG_REASONS = [
    'Deceased',
    'Duplicate',
    'High-Risk',
    'Hospitalized',
    'In Need of Follow-up',
    'Lost to Follow-up',
    'Needs Interpretation',
    'Quality Assurance',
    'Refused Active Monitoring',
    'Other'
  ].freeze

  RACE_OPTIONS = {
    non_exclusive: [
      { race: :white, label: 'WHITE' },
      { race: :black_or_african_american, label: 'BLACK OR AFRICAN AMERICAN' },
      { race: :american_indian_or_alaska_native, label: 'AMERICAN INDIAN OR ALASKA NATIVE' },
      { race: :asian, label: 'ASIAN' },
      { race: :native_hawaiian_or_other_pacific_islander, label: 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' },
      { race: :race_other, label: 'OTHER' }
    ],
    exclusive: [
      { race: :race_unknown, label: 'UNKNOWN' },
      { race: :race_refused_to_answer, label: 'REFUSED TO ANSWER' }
    ]
  }.freeze

  SYSTEM_SELECTABLE_MONITORING_REASONS = [
    'Enrolled more than 14 days after last date of exposure (system)',
    'Enrolled more than 10 days after last date of exposure (system)',
    'Enrolled on last day of monitoring period (system)',
    'Completed Monitoring (system)',
    'No record activity for 30 days (system)',
    '',
    nil
  ].freeze

  TIME_OPTIONS = {
    Morning: 'Morning',
    Afternoon: 'Afternoon',
    Evening: 'Evening',
    '0': 'Midnight',
    '1': '01:00',
    '2': '02:00',
    '3': '03:00',
    '4': '04:00',
    '5': '05:00',
    '6': '06:00',
    '7': '07:00',
    '8': '08:00',
    '9': '09:00',
    '10': '10:00',
    '11': '11:00',
    '12': 'Noon',
    '13': '13:00',
    '14': '14:00',
    '15': '15:00',
    '16': '16:00',
    '17': '17:00',
    '18': '18:00',
    '19': '19:00',
    '20': '20:00',
    '21': '21:00',
    '22': '22:00',
    '23': '23:00'
  }.freeze

  NORMALIZED_INVERTED_TIME_OPTIONS = TIME_OPTIONS.invert.merge({ '0': '00:00', '12': '12:00' }.invert).transform_keys(&:downcase).freeze

  VALID_PATIENT_ENUMS = {
    # identification
    sex: ['Male', 'Female', 'Unknown', nil, ''],
    gender_identity: ['Male (Identifies as male)', 'Female (Identifies as female)', 'Transgender Male (Female-to-Male [FTM])',
                      'Transgender Female (Male-to-Female [MTF])', 'Genderqueer / gender nonconforming (neither exclusively male nor female)', 'Another',
                      'Chose not to disclose'],
    sexual_orientation: ['Straight or Heterosexual', 'Lesbian, Gay, or Homosexual', 'Bisexual', 'Another', 'Choose not to disclose', 'Don’t know'],
    ethnicity: ['Not Hispanic or Latino', 'Hispanic or Latino', 'Unknown', 'Refused to Answer', nil, ''],
    primary_language: [*VALID_LANGUAGES, nil, ''],
    secondary_language: [*VALID_LANGUAGES, nil, ''],
    # address
    address_state: [*VALID_STATES, nil, ''],
    monitored_address_state: [*VALID_STATES, nil, ''],
    foreign_monitored_address_state: [*VALID_STATES, nil, ''],
    # contact info
    preferred_contact_method: ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out', 'Unknown', nil, ''],
    primary_telephone_type: ['Smartphone', 'Plain Cell', 'Landline', nil, ''],
    secondary_telephone_type: ['Smartphone', 'Plain Cell', 'Landline', nil, ''],
    preferred_contact_time: TIME_OPTIONS.keys.map(&:to_s) + [nil, ''],
    # arrival
    source_of_report: ['Health Screening', 'Surveillance Screening', 'Self-Identified', 'Contact Tracing', 'CDC', 'Other', nil, ''],
    # additional planned travel
    additional_planned_travel_type: ['Domestic', 'International', nil, ''],
    additional_planned_travel_destination_state: [*VALID_STATES, nil, ''],
    # potential exposure/case info
    case_status: ['Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case', nil, ''],
    exposure_risk_assessment: ['High', 'Medium', 'Low', 'No Identified Risk', nil, ''],
    monitoring_plan: ['None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision',
                      'Self-observation', '', nil],
    # other monitoring fields
    public_health_action: ['None', 'Recommended medical evaluation of symptoms', 'Document results of medical evaluation', 'Recommended laboratory testing',
                           nil, ''],
    monitoring_reason: USER_SELECTABLE_MONITORING_REASONS + SYSTEM_SELECTABLE_MONITORING_REASONS,
    follow_up_reason: [*FOLLOW_UP_FLAG_REASONS, nil],
    # laboratories
    lab_type: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other', nil, ''],
    result: ['positive', 'negative', 'indeterminate', 'other', nil, ''],
    # vaccines
    group_name: Vaccine.group_name_options,
    product_name: (Vaccine.group_name_options.map { |group_name| Vaccine.product_name_options(group_name) }).flatten,
    dose_number: Vaccine::DOSE_OPTIONS
  }.freeze

  VALID_EXPOSURE_ENUMS = {
    case_status: ['Suspect', 'Unknown', 'Not a Case']
  }.freeze

  VALID_ISOLATION_ENUMS = {
    case_status: %w[Confirmed Probable]
  }.freeze

  def self.normalize_enums(enums)
    enums.transform_values do |values|
      values.collect { |value| [value.to_s.downcase.gsub(/[ -.]/, ''), value] }.to_h
    end
  end

  NORMALIZED_ENUMS = normalize_enums(VALID_PATIENT_ENUMS)

  NORMALIZED_EXPOSURE_ENUMS = normalize_enums(VALID_EXPOSURE_ENUMS)

  NORMALIZED_ISOLATION_ENUMS = normalize_enums(VALID_ISOLATION_ENUMS)

  VALIDATION = {
    # identification
    first_name: { label: 'First Name', checks: [:required] },
    last_name: { label: 'Last Name', checks: [:required] },
    date_of_birth: { label: 'Date of Birth', checks: %i[required date] },
    sex: { label: 'Sex', checks: [:sex] },
    white: { label: 'White', checks: [:bool] },
    black_or_african_american: { label: 'Black or African American', checks: [:bool] },
    american_indian_or_alaska_native: { label: 'American Indian or Alaska Native', checks: [:bool] },
    asian: { label: 'Asian', checks: [:bool] },
    native_hawaiian_or_other_pacific_islander: { label: 'Native Hawaiian or Other Pacific Islander', checks: [:bool] },
    race_other: { label: 'Race Other', checks: [:bool] },
    race_unknown: { label: 'Race Unknown', checks: [:bool] },
    race_refused_to_answer: { label: 'Race Refused to Answer', checks: [:bool] },
    ethnicity: { label: 'Ethnicity', checks: [:enum] },
    primary_language: { label: 'Primary Language', checks: [:lang] },
    secondary_language: { label: 'Secondary Language', checks: [:lang] },
    interpretation_required: { label: 'Interpretation Required?', checks: [:bool] },
    gender_identity: { label: 'Gender Identity', checks: [] },
    sexual_orientation: { label: 'Sexual Orientation', checks: [] },
    # address
    address_state: { label: 'State', checks: %i[required state] },
    monitored_address_state: { label: 'Monitored Address State', checks: [:state] },
    foreign_monitored_address_state: { label: 'Foreign Monitored Address State', checks: [:state] },
    # contact info
    preferred_contact_method: { label: 'Preferred Contact Method', checks: [:enum] },
    preferred_contact_time: { label: 'Preferred Contact Time', checks: %i[time] },
    primary_telephone: { label: 'Primary Telephone', checks: [:phone] },
    primary_telephone_type: { label: 'Primary Telephone Type', checks: [:enum] },
    secondary_telephone: { label: 'Secondary Telephone', checks: [:phone] },
    secondary_telephone_type: { label: 'Secondary Telephone Type', checks: [:enum] },
    email: { label: 'Email', checks: [:email] },
    # arrival info
    date_of_departure: { label: 'Date of Departure', checks: [:date] },
    date_of_arrival: { label: 'Date of Arrival', checks: [:date] },
    source_of_report: { label: 'Source of Report', checks: [:enum] },
    source_of_report_specify: { label: 'Source of Report Specify', checks: [:enum] },
    # additional planned travel
    additional_planned_travel_type: { label: 'Additional Planned Travel Type', checks: [:enum] },
    additional_planned_travel_destination_state: { label: 'Additional Planned Travel Destination State', checks: [:state] },
    additional_planned_travel_start_date: { label: 'Additional Planned Travel Start Date', checks: [:date] },
    additional_planned_travel_end_date: { label: 'Additional Planned Travel End Date', checks: [:date] },
    # potential exposure/case info
    last_date_of_exposure: { label: 'Last Date of Exposure', checks: %i[required date] },
    continuous_exposure: { label: 'Continuous Exposure', checks: [:bool] },
    symptom_onset: { label: 'Symptom Onset', checks: [:date] },
    case_status: { label: 'Case Status', checks: [:enum] },
    contact_of_known_case: { label: 'Contact of Known Case?', checks: [:bool] },
    travel_to_affected_country_or_area: { label: 'Travel from Affected Country or Area?', checks: [:bool] },
    was_in_health_care_facility_with_known_cases: { label: 'Was in Health Care Facility With Known Cases?', checks: [:bool] },
    laboratory_personnel: { label: 'Laboratory Personnel?', checks: [:bool] },
    healthcare_personnel: { label: 'Healthcare Personnel?', checks: [:bool] },
    crew_on_passenger_or_cargo_flight: { label: 'Crew on Passenger or Cargo Flight?', checks: [:bool] },
    member_of_a_common_exposure_cohort: { label: 'Member of a Common Exposure Cohort?', checks: [:bool] },
    jurisdiction_id: { label: 'Jurisdiction ID', checks: [] },
    assigned_user: { label: 'Assigned User', checks: [] },
    exposure_risk_assessment: { label: 'Exposure Risk Assessment', checks: [:enum] },
    monitoring_plan: { label: 'Monitoring Plan', checks: [:enum] },
    # other monitoring fields
    patient_id: { label: 'Patient ID', checks: [] },
    public_health_action: { label: 'Public Health Action', checks: [] },
    extended_isolation: { label: 'Extended Isolation', checks: [:date] },
    contact_attempts: { label: 'Contact Attempts', checks: [] },
    follow_up_reason: { label: 'Follow-Up Reason', checks: [:enum] },
    follow_up_note: { label: 'Follow-Up Note', checks: [] },
    # laboratories
    lab_type: { label: 'Lab Test Type', checks: [:enum] },
    specimen_collection: { label: 'Lab Specimen Collection Date', checks: [:date] },
    report: { label: 'Lab Report Date', checks: [:date] },
    result: { label: 'Lab Result', checks: [:enum] },
    # vaccines
    group_name: { label: 'Vaccine Group Name', checks: [:enum] },
    product_name: { label: 'Vaccine Product Name', checks: [:enum] },
    administration_date: { label: 'Vaccine Administration Date', checks: [:date] },
    dose_number: { label: 'Vaccine Dose Number', checks: [:enum] },
    notes: { label: 'Vaccine Notes', checks: [] }
  }.freeze

  # Validates if a given date value is between (inclusive) two dates.
  def validate_between_dates(record, attribute, earliest_date, latest_date)
    return if attribute.nil? || record.nil? || !record.has_attribute?(attribute)

    # Get the new value to validate
    value = record[attribute]
    return if value.nil?

    # Validate that the value acts like a Date and add error otherwise
    attribute_label = attribute&.to_s&.humanize&.titleize
    record.errors.add(attribute, "#{value} is not valid for the #{attribute_label} field. Must be a valid date.") && return unless value.acts_like?(:date)

    # Validate inclusivity of Date, and add error if not valid
    is_valid = value >= earliest_date && value <= latest_date
    return if is_valid

    err_message = "#{value} is not valid for the #{attribute_label} field. Must be a valid date between (inclusive) #{earliest_date} and #{latest_date}."
    record.errors.add(attribute, err_message)
  end

  # Format validation errors from the model to be more human-readable
  def format_model_validation_errors(resource)
    resource.errors&.messages&.each_with_object([]) do |(attribute, errors), messages|
      next unless VALIDATION.key?(attribute) || attribute == :base

      # NOTE: If the value is a date, the typecast value may not correspond to original user input, so get value_before_type_cast
      unless attribute == :base
        value = VALIDATION.dig(attribute, :checks)&.include?(:date) ? resource.public_send("#{attribute}_before_type_cast") : resource[attribute]
        msg_header = (value ? "Value '#{value}' for " : '') + "'#{VALIDATION[attribute][:label]}'"
      end
      errors.each do |error_message|
        # Exclude the actual value in logging to avoid PII/PHI
        Rails.logger.info "Validation Error on: #{attribute}"
        messages << "#{msg_header} #{error_message}".strip
      end
    end
  end
end
