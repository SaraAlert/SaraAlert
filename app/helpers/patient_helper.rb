# frozen_string_literal: true

# Helper methods for the patient model
module PatientHelper # rubocop:todo Metrics/ModuleLength
  # Build a FHIR US Core Race Extension given Sara Alert race booleans.
  def us_core_race(white, black_or_african_american, american_indian_or_alaska_native, asian, native_hawaiian_or_other_pacific_islander)
    # Don't return an extension if all race categories are false or nil
    return nil unless [white, black_or_african_american, american_indian_or_alaska_native, asian, native_hawaiian_or_other_pacific_islander].include?(true)

    # Build out extension based on what race categories are true
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race', extension: [
      white ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2106-3', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'White')
      ) : nil,
      black_or_african_american ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2054-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Black or African American')
      ) : nil,
      american_indian_or_alaska_native ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '1002-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'American Indian or Alaska Native')
      ) : nil,
      asian ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2028-9', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Asian')
      ) : nil,
      native_hawaiian_or_other_pacific_islander ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2076-8', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Native Hawaiian or Other Pacific Islander')
      ) : nil,
      FHIR::Extension.new(
        url: 'text',
        valueString: [white ? 'White' : nil,
                      black_or_african_american ? 'Black or African American' : nil,
                      american_indian_or_alaska_native ? 'American Indian or Alaska Native' : nil,
                      asian ? 'Asian' : nil,
                      native_hawaiian_or_other_pacific_islander ? 'Native Hawaiian or Other Pacific Islander' : nil].reject(&:nil?).join(', ')
      )
    ].reject(&:nil?))
  end

  # Return a boolean indicating if the given race code is present on the given FHIR::Patient.
  def self.race_code?(patient, code)
    url = 'us-core-race'
    patient&.extension&.select { |e| e.url.include?(url) }&.first&.extension&.select { |e| e.url == 'ombCategory' }&.first&.valueCoding&.code == code
  end

  # Build a FHIR US Core Ethnicity Extension given Sara Alert ethnicity information.
  def us_core_ethnicity(ethnicity)
    # Don't return an extension if no ethnicity specified
    return nil unless ['Hispanic or Latino', 'Not Hispanic or Latino'].include?(ethnicity)

    # Build out extension based on what ethnicity was specified
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity', extension: [
                          ethnicity == 'Hispanic or Latino' ? FHIR::Extension.new(
                            url: 'ombCategory',
                            valueCoding: FHIR::Coding.new(code: '2135-2', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Hispanic or Latino')
                          ) : nil,
                          ethnicity == 'Not Hispanic or Latino' ? FHIR::Extension.new(
                            url: 'ombCategory',
                            valueCoding: FHIR::Coding.new(code: '2186-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Not Hispanic or Latino')
                          ) : nil,
                          FHIR::Extension.new(
                            url: 'text',
                            valueString: ethnicity
                          )
                        ])
  end

  # Return a string representing the ethnicity of the given FHIR::Patient
  def self.ethnicity(patient)
    url = 'us-core-ethnicity'
    code = patient&.extension&.select { |e| e.url.include?(url) }&.first&.extension&.select { |e| e.url == 'ombCategory' }&.first&.valueCoding&.code
    return 'Hispanic or Latino' if code == '2135-2'
    return 'Not Hispanic or Latino' if code == '2186-5'

    nil
  end

  # Build a FHIR US Core BirthSex Extension given Sara Alert sex information.
  def us_core_birthsex(sex)
    # Don't return an extension if no sex specified
    return nil unless %w[Male Female Unknown].include?(sex)

    # Build out extension based on what sex was specified
    code = sex == 'Unknown' ? 'UNK' : sex.first
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex', valueCode: code)
  end

  # Return a string representing the birthsex of the given FHIR::Patient
  def self.birthsex(patient)
    url = 'us-core-birthsex'
    code = patient&.extension&.select { |e| e.url.include?(url) }&.first&.valueCode
    return 'Male' if code == 'M'
    return 'Female' if code == 'F'
    return 'Unknown' if code == 'UNK'

    nil
  end

  # Helper to create an extension for preferred contact method
  def to_preferred_contact_method_extension(preferred_contact_method)
    preferred_contact_method.nil? ? nil : FHIR::Extension.new(
      url: 'http://saraalert.org/StructureDefinition/preferred-contact-method',
      valueString: preferred_contact_method
    )
  end

  # Helper to understand an extension for preferred contact method
  def self.from_preferred_contact_method_extension(patient)
    pcm = patient&.extension&.select { |e| e.url.include?('preferred-contact-method') }&.first&.valueString
    pcm = nil unless ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message', 'Opt-out', 'Unknown'].include?(pcm)
    pcm
  end

  # Helper to create an extension for preferred contact time
  def to_preferred_contact_time_extension(_preferred_contact_method)
    preferred_contact_time.nil? ? nil : FHIR::Extension.new(
      url: 'http://saraalert.org/StructureDefinition/preferred-contact-time',
      valueString: preferred_contact_time
    )
  end

  # Helper to understand an extension for preferred contact time
  def self.from_preferred_contact_time_extension(patient)
    pct = patient&.extension&.select { |e| e.url.include?('preferred-contact-time') }&.first&.valueString
    pct = nil unless %w[Morning Afternoon Evening].include?(pct)
    pct
  end

  # Helper to create an extension for symptom onset date
  def to_symptom_onset_date_extension(symptom_onset)
    symptom_onset.nil? ? nil : FHIR::Extension.new(
      url: 'http://saraalert.org/StructureDefinition/symptom-onset-date',
      valueDate: symptom_onset
    )
  end

  # Helper to understand an extension for symptom onset date
  def self.from_symptom_onset_date_extension(patient)
    Date.strptime(patient&.extension&.select { |e| e.url.include?('symptom-onset-date') }&.first&.valueDate&.to_s || '', '%Y-%m-%d')
  rescue ArgumentError
    nil
  end

  # Helper to create an extension for last exposure date
  def to_last_exposure_date_extension(last_exposure)
    last_exposure.nil? ? nil : FHIR::Extension.new(
      url: 'http://saraalert.org/StructureDefinition/last-exposure-date',
      valueDate: last_exposure
    )
  end

  # Helper to understand an extension for last exposure date
  def self.from_last_exposure_date_extension(patient)
    Date.strptime(patient&.extension&.select { |e| e.url.include?('last-exposure-date') }&.first&.valueDate&.to_s || '', '%Y-%m-%d')
  rescue ArgumentError
    nil
  end

  # Helper to create an extension for isolation status
  def to_isolation_extension(isolation)
    FHIR::Extension.new(
      url: 'http://saraalert.org/StructureDefinition/isolation',
      valueBoolean: isolation
    )
  end
   
  def to_state_or_local_extension( state_or_local_id )
    FHIR::Extension.new(
      url: 'http://saraalert.org/StructureDefinition/state-or-local-id',
      valueString: state_or_local_id
    )
  end

  def to_contact_of_known_case_extension( contact_of_known_case )
    FHIR::Extension.new(
      url: 'http://saraalert.org/StructureDefinition/contact-of-known-cas',
      valueBoolean: contact_of_known_case
    )
  end

  def to_contact_of_known_case_id_extension( contact_of_known_case_id )
    FHIR::Extension.new(
      url: 'http://saraalert.org/StructureDefinition/contact-of-known-case-id',
      valueString: contact_of_known_case_id
    )
  end


  # Helper to understand an extension for last exposure date
  def self.from_isolation_extension(patient)
    patient&.extension&.select { |e| e.url.include?('isolation') }&.first&.valueBoolean == true
  end

  # Helper to understand state or local
  def self.from_id_statelocal_extension(patient)
    id_statelocal = patient&.extension&.select { |e| e.url.include?('state-or-local-id') }&.first&.valueString
    id_statelocal

  end

  # Helper to understand contact_of_known_case
  def self.from_contact_of_known_case_extension(patient)
    contact_of_known_case = patient&.extension&.select { |e| e.url.include?('contact-of-known-case') }&.first&.valueString
    contact_of_known_case

  end

  # Helper to understand contact_of_known_case_id
  def self.from_contact_of_known_case_id_extension(patient)
    contact_of_known_case_id = patient&.extension&.select { |e| e.url.include?('contact-of-known-case-id') }&.first&.valueString
    contact_of_known_case_id

  end

  # Helper to understand contact_of_known_case_id
  def self.from_jurisdiction_extension(patient)
    jurisdiction = patient&.extension&.select { |e| e.url.include?('jurisdiction') }&.first&.valueString
    Jurisdiction.where(id: jurisdiction).first
  end

  def to_jurisdiction_extension(jurisdiction)
    FHIR::Extension.new( url: 'http://saraalert.org/StructureDefinition/jurisdiction', valueString: jurisdiction.id)
  end


  def self.from_exposure_risk_assessment_extension(patient)
    exposure_risk_assessment = patient&.extension&.select { |e| e.url.include?('exposure-risk-assessment') }&.first&.valueString
    exposure_risk_assessment
  end

  def to_exposure_risk_assessment_extension(exposure_risk_assessment)
    FHIR::Extension.new(
        url: 'http://saraalert.org/StructureDefinition/exposure-risk-assessment',
        valueString: exposure_risk_assessment
    )
  end

  def self.from_monitoring_status_extension(patient)
    monitoring_status = patient&.extension&.select { |e| e.url.include?('monitoring-status') }&.first&.valueString
    monitoring_status
  end

  def to_monitoring_status_extension( monitoring_status )
    FHIR::Extension.new(
        url: 'http://saraalert.org/StructureDefinition/monitoring-status',
        valueString: monitoring_status
    )
  end

  def self.from_monitoring_plan_extension(patient)
    monitoring_plan = patient&.extension&.select { |e| e.url.include?('monitoring-plan') }&.first&.valueString
    monitoring_plan
  end

  def to_monitoring_plan_extension( monitoring_plan )
    FHIR::Extension.new(
        url: 'http://saraalert.org/StructureDefinition/monitoring-plan',
        valueString: monitoring_plan
    )
  end

  def self.from_case_status_extension(patient)
    case_status = patient&.extension&.select { |e| e.url.include?('case-status') }&.first&.valueString
    # logger.info("case_status: " + case_status)
    case_status
  end

  def to_case_status_extension( case_status )
    FHIR::Extension.new(
        url: 'http://saraalert.org/StructureDefinition/case-status',
        valueString: case_status
    )
  end

  def self.from_assigned_user_extension(patient)
    assigned_user = patient&.extension&.select { |e| e.url.include?('assigned-user') }&.first&.valueInteger
    assigned_user
  end

  def to_assigned_user_extension( assigned_user )
    FHIR::Extension.new(
        url: 'http://saraalert.org/StructureDefinition/assigned-user',
        valueInteger: assigned_user
    )
  end

  def to_status_extension( status )
    FHIR::Extension.new(
        url: 'http://saraalert.org/StructureDefinition/status',
        valueString: status
    )
  end

  def self.from_user_defined_id_nndss_extension(patient)
    user_defined_id_nndss = patient&.extension&.select { |e| e.url.include?('user-defined-id-nndss') }&.first&.valueString
    user_defined_id_nndss
  end


  def to_user_defined_id_nndss_extension(user_defined_id_nndss)
    FHIR::Extension.new(
        url: 'http://saraalert.org/StructureDefinition/user-defined-id-nndss',
        valueString: user_defined_id_nndss
    )
  end

  def self.from_public_health_action_extension(patient)
    public_health_action = patient&.extension&.select { |e| e.url.include?('public-health-action') }&.first&.valueString
    public_health_action
  end

  def to_public_health_action_extension(public_health_action)
    FHIR::Extension.new(
        url: 'http://saraalert.org/StructureDefinition/public-health-action',
        valueString: assigned_user
    )
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
    # This list contains all of the same states listed in app/javascript/components/data.js
    state_names = {
      'alabama' => 'Alabama',
      'alaska' => 'Alaska',
      'americansamoa' => 'American Samoa',
      'arizona' => 'Arizona',
      'arkansas' => 'Arkansas',
      'california' => 'California',
      'colorado' => 'Colorado',
      'connecticut' => 'Connecticut',
      'delaware' => 'Delaware',
      'districtofcolumbia' => 'District of Columbia',
      'federatedstatesofmicronesia' => 'Federated States of Micronesia',
      'florida' => 'Florida',
      'georgia' => 'Georgia',
      'guam' => 'Guam',
      'hawaii' => 'Hawaii',
      'idaho' => 'Idaho',
      'illinois' => 'Illinois',
      'indiana' => 'Indiana',
      'iowa' => 'Iowa',
      'kansas' => 'Kansas',
      'kentucky' => 'Kentucky',
      'louisiana' => 'Louisiana',
      'maine' => 'Maine',
      'marshallislands' => 'Marshall Islands',
      'maryland' => 'Maryland',
      'massachusetts' => 'Massachusetts',
      'michigan' => 'Michigan',
      'minnesota' => 'Minnesota',
      'mississippi' => 'Mississippi',
      'missouri' => 'Missouri',
      'montana' => 'Montana',
      'nebraska' => 'Nebraska',
      'nevada' => 'Nevada',
      'newhampshire' => 'New Hampshire',
      'newjersey' => 'New Jersey',
      'newmexico' => 'New Mexico',
      'newyork' => 'New York',
      'northcarolina' => 'North Carolina',
      'northdakota' => 'North Dakota',
      'northernmarianaislands' => 'Northern Mariana Islands',
      'ohio' => 'Ohio',
      'oklahoma' => 'Oklahoma',
      'oregon' => 'Oregon',
      'palau' => 'Palau',
      'pennsylvania' => 'Pennsylvania',
      'puertorico' => 'Puerto Rico',
      'rhodeisland' => 'Rhode Island',
      'southcarolina' => 'South Carolina',
      'southdakota' => 'South Dakota',
      'tennessee' => 'Tennessee',
      'texas' => 'Texas',
      'utah' => 'Utah',
      'vermont' => 'Vermont',
      'virginislands' => 'Virgin Islands',
      'virginia' => 'Virginia',
      'washington' => 'Washington',
      'westvirginia' => 'West Virginia',
      'wisconsin' => 'Wisconsin',
      'wyoming' => 'Wyoming'
    }
    state_names[normalize_name(name)] || nil
  end

  def timezone_for_state(name)
    timezones = {
      'alabama' => '-05:00',
      'alaska' => '-08:00',
      'americansamoa' => '-11:00',
      'arizona' => '-07:00',
      'arkansas' => '-05:00',
      'california' => '-07:00',
      'colorado' => '-06:00',
      'connecticut' => '-04:00',
      'delaware' => '-04:00',
      'districtofcolumbia' => '-04:00',
      'federatedstatesofmicronesia' => '+11:00',
      'florida' => '-04:00',
      'georgia' => '-04:00',
      'guam' => '+10:00',
      'hawaii' => '-10:00',
      'idaho' => '-06:00',
      'illinois' => '-05:00',
      'indiana' => '-04:00',
      'iowa' => '-05:00',
      'kansas' => '-05:00',
      'kentucky' => '-04:00',
      'louisiana' => '-05:00',
      'maine' => '-04:00',
      'marshallislands' => '+12:00',
      'maryland' => '-04:00',
      'massachusetts' => '-04:00',
      'michigan' => '-04:00',
      'minnesota' => '-05:00',
      'mississippi' => '-05:00',
      'missouri' => '-05:00',
      'montana' => '-06:00',
      'nebraska' => '-05:00',
      'nevada' => '-07:00',
      'newhampshire' => '-04:00',
      'newjersey' => '-04:00',
      'newmexico' => '-06:00',
      'newyork' => '-04:00',
      'northcarolina' => '-04:00',
      'northdakota' => '-05:00',
      'northernmarianaislands' => '+10:00',
      'ohio' => '-04:00',
      'oklahoma' => '-05:00',
      'oregon' => '-07:00',
      'palau' => '+09:00',
      'pennsylvania' => '-04:00',
      'puertorico' => '-04:00',
      'rhodeisland' => '-04:00',
      'southcarolina' => '-04:00',
      'southdakota' => '-05:00',
      'tennessee' => '-05:00',
      'texas' => '-05:00',
      'utah' => '-06:00',
      'vermont' => '-04:00',
      'virginislands' => '-04:00',
      'virginia' => '-04:00',
      'washington' => '-07:00',
      'westvirginia' => '-04:00',
      'wisconsin' => '-05:00',
      'wyoming' => '-06:00',
      nil => '-04:00',
      '' => '-04:00'
    }
    timezones[normalize_name(name)] || '-04:00'
  end

  # Given a language string, try to find the corresponding BCP 47 code for it and construct a FHIR::Coding.
  def language_coding(language)
    PatientHelper.languages(language&.downcase) ? FHIR::Coding.new(**PatientHelper.languages(language&.downcase)) : nil
  end

  def self.languages(language)
    languages = {
      'arabic': { code: 'ar', display: 'Arabic', system: 'urn:ietf:bcp:47' },
      'bengali': { code: 'bn', display: 'Bengali', system: 'urn:ietf:bcp:47' },
      'czech': { code: 'cs', display: 'Czech', system: 'urn:ietf:bcp:47' },
      'danish': { code: 'da', display: 'Danish', system: 'urn:ietf:bcp:47' },
      'german': { code: 'de', display: 'German', system: 'urn:ietf:bcp:47' },
      'greek': { code: 'el', display: 'Greek', system: 'urn:ietf:bcp:47' },
      'english': { code: 'en', display: 'English', system: 'urn:ietf:bcp:47' },
      'spanish': { code: 'es', display: 'Spanish', system: 'urn:ietf:bcp:47' },
      'finnish': { code: 'fi', display: 'Finnish', system: 'urn:ietf:bcp:47' },
      'french': { code: 'fr', display: 'French', system: 'urn:ietf:bcp:47' },
      'frysian': { code: 'fy', display: 'Frysian', system: 'urn:ietf:bcp:47' },
      'hindi': { code: 'hi', display: 'Hindi', system: 'urn:ietf:bcp:47' },
      'croatian': { code: 'hr', display: 'Croatian', system: 'urn:ietf:bcp:47' },
      'italian': { code: 'it', display: 'Italian', system: 'urn:ietf:bcp:47' },
      'japanese': { code: 'ja', display: 'Japanese', system: 'urn:ietf:bcp:47' },
      'korean': { code: 'ko', display: 'Korean', system: 'urn:ietf:bcp:47' },
      'dutch': { code: 'nl', display: 'Dutch', system: 'urn:ietf:bcp:47' },
      'norwegian': { code: 'no', display: 'Norwegian', system: 'urn:ietf:bcp:47' },
      'punjabi': { code: 'pa', display: 'Punjabi', system: 'urn:ietf:bcp:47' },
      'polish': { code: 'pl', display: 'Polish', system: 'urn:ietf:bcp:47' },
      'portuguese': { code: 'pt', display: 'Portuguese', system: 'urn:ietf:bcp:47' },
      'russian': { code: 'ru', display: 'Russian', system: 'urn:ietf:bcp:47' },
      'serbian': { code: 'sr', display: 'Serbian', system: 'urn:ietf:bcp:47' },
      'swedish': { code: 'sv', display: 'Swedish', system: 'urn:ietf:bcp:47' },
      'telegu': { code: 'te', display: 'Telegu', system: 'urn:ietf:bcp:47' },
      'chinese': { code: 'zh', display: 'Chinese', system: 'urn:ietf:bcp:47' },
      'vietnamese': { code: 'vi', display: 'Vietnamese', system: 'urn:ietf:bcp:47' },
      'tagalog': { code: 'tl', display: 'Tagalog', system: 'urn:ietf:bcp:47' },
      'somali': { code: 'so', display: 'Somali', system: 'urn:ietf:bcp:47' },
      'nepali': { code: 'ne', display: 'Nepali', system: 'urn:ietf:bcp:47' },
      'swahili': { code: 'sw', display: 'Swahili', system: 'urn:ietf:bcp:47' },
      'burmese': { code: 'my', display: 'Burmese', system: 'urn:ietf:bcp:47' },
      'spanish (puerto rican)': { code: 'es-PR', display: 'Spanish (Puerto Rican)', system: 'urn:ietf:bcp:47' }
    }
    languages[language&.downcase&.to_sym].present? ? languages[language&.downcase&.to_sym] : nil
  end

end
