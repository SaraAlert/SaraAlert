# frozen_string_literal: true

# ValidationHelper: Helper constants and methods for validation.
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
    'Deceased',
    'Duplicate',
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
    'Enrolled more than 14 days after last date of exposure (system)', 'Enrolled more than 10 days after last date of exposure (system)',
    'Enrolled on last day of monitoring period (system)', 'Completed Monitoring (system)', '', nil
  ].freeze

  VALID_PATIENT_ENUMS = {
    gender_identity: ['Male (Identifies as male)', 'Female (Identifies as female)', 'Transgender Male (Female-to-Male [FTM])',
                      'Transgender Female (Male-to-Female [MTF])', 'Genderqueer / gender nonconforming (neither exclusively male nor female)', 'Another',
                      'Chose not to disclose'],
    sexual_orientation: ['Straight or Heterosexual', 'Lesbian, Gay, or Homosexual', 'Bisexual', 'Another', 'Choose not to disclose', 'Don’t know'],
    ethnicity: ['Not Hispanic or Latino', 'Hispanic or Latino', 'Unknown', 'Refused to Answer', nil, ''],
    preferred_contact_method: ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out', 'Unknown', nil, ''],
    primary_telephone_type: ['Smartphone', 'Plain Cell', 'Landline', nil, ''],
    secondary_telephone_type: ['Smartphone', 'Plain Cell', 'Landline', nil, ''],
    preferred_contact_time: ['Morning', 'Afternoon', 'Evening', nil, ''],
    additional_planned_travel_type: ['Domestic', 'International', nil, ''],
    exposure_risk_assessment: ['High', 'Medium', 'Low', 'No Identified Risk', nil, ''],
    monitoring_reason: USER_SELECTABLE_MONITORING_REASONS + SYSTEM_SELECTABLE_MONITORING_REASONS,
    monitoring_plan: ['None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision',
                      'Self-observation', '', nil],
    case_status: ['Confirmed', 'Probable', 'Suspect', 'Unknown', 'Not a Case', nil, ''],
    lab_type: ['PCR', 'Antigen', 'Total Antibody', 'IgG Antibody', 'IgM Antibody', 'IgA Antibody', 'Other', nil, ''],
    result: ['positive', 'negative', 'indeterminate', 'other', nil, ''],
    sex: ['Male', 'Female', 'Unknown', nil, ''],
    address_state: [*VALID_STATES, nil, ''],
    monitored_address_state: [*VALID_STATES, nil, ''],
    public_health_action: ['None', 'Recommended medical evaluation of symptoms', 'Document results of medical evaluation', 'Recommended laboratory testing'],
    source_of_report: ['Health Screening', 'Surveillance Screening', 'Self-Identified', 'Contact Tracing', 'CDC', 'Other'],
    foreign_monitored_address_state: [*VALID_STATES, nil, ''],
    additional_planned_travel_destination_state: [*VALID_STATES, nil, '']
  }.freeze

  VALID_EXPOSURE_ENUMS = {
    case_status: ['Suspect', 'Unknown', 'Not a Case']
  }.freeze

  VALID_ISOLATION_ENUMS = {
    case_status: %w[Confirmed Probable]
  }.freeze

  def self.normalize_enums(enums_dict)
    enums_dict.transform_values do |values|
      Hash[values.collect { |value| [value.to_s.downcase.gsub(/[ -.]/, ''), value] }]
    end
  end

  NORMALIZED_ENUMS = normalize_enums(VALID_PATIENT_ENUMS)

  NORMALIZED_EXPOSURE_ENUMS = normalize_enums(VALID_EXPOSURE_ENUMS)

  NORMALIZED_ISOLATION_ENUMS = normalize_enums(VALID_ISOLATION_ENUMS)

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
    race_other: { label: 'Race Other', checks: [:bool] },
    race_unknown: { label: 'Race Unknown', checks: [:bool] },
    race_refused_to_answer: { label: 'Race Refused to Answer', checks: [:bool] },
    ethnicity: { label: 'Ethnicity', checks: [:enum] },
    interpretation_required: { label: 'Interpretation Required?', checks: [:bool] },
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
    jurisdiction_id: { label: 'Jurisdiction ID', checks: [] },
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
    result: { label: 'Result', checks: [:enum] },
    assigned_user: { label: 'Assigned User', checks: [] },
    continuous_exposure: { label: 'Continuous Exposure', checks: [:bool] },
    patient_id: { label: 'Patient ID', checks: [] },
    contact_attempts: { label: 'Contact Attempts', checks: [] },
    administration_date: { label: 'Administration Date', checks: [] },
    dose_number: { label: 'Dose Number', checks: [] },
    notes: { label: 'Notes', checks: [] },
    group_name: { label: 'Vaccine Group', checks: [] },
    product_name: { label: 'Product Name', checks: [] }
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
