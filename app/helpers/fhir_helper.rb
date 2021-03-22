# frozen_string_literal: true

# Helper module for FHIR translations
module FhirHelper # rubocop:todo Metrics/ModuleLength
  SA_EXT_BASE_URL = 'http://saraalert.org/StructureDefinition/'.freeze
  DATA_ABSENT_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'.freeze
  OMB_URL = 'ombCategory'.freeze
  DETAILED_URL = 'detailed'.freeze

  # Returns a representative FHIR::Patient for an instance of a Sara Alert Patient. Uses US Core
  # extensions for sex, race, and ethnicity.
  # https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-patient.html
  def patient_as_fhir(patient)
    return nil if patient.nil?

    creator_agent_ref = FHIR::Reference.new
    if patient.creator.is_api_proxy
      # Created with an M2M workflow client
      creator_app = OauthApplication.find_by(user_id: patient.creator.id)
      creator_agent_ref.identifier = FHIR::Identifier.new(value: creator_app.uid)
      creator_agent_ref.display = creator_app.name
    else
      # Created with a user worfklow client or a human user
      creator_agent_ref.identifier = FHIR::Identifier.new(value: patient.creator.id)
      creator_agent_ref.display = patient.creator.email
    end

    FHIR::Patient.new(
      meta: FHIR::Meta.new(lastUpdated: patient.updated_at.strftime('%FT%T%:z')),
      contained: [FHIR::Provenance.new(
        # Would like to use a Rails URL Helper here, but we don't get one for this endpoint
        target: [FHIR::Reference.new(reference: "/fhir/r4/Patient/#{patient.id}")],
        agent: [
          FHIR::Provenance::Agent.new(
            who: creator_agent_ref
          )
        ],
        recorded: patient.created_at.strftime('%FT%T%:z'),
        activity: {
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/v3-DataOperation',
              code: 'CREATE',
              display: 'create'
            }
          ]
        }
      )],
      id: patient.id,
      identifier: [to_statelocal_identifier(patient.user_defined_id_statelocal)],
      active: patient.monitoring,
      name: [FHIR::HumanName.new(given: [patient.first_name, patient.middle_name].reject(&:blank?), family: patient.last_name)],
      telecom: [
        patient.primary_telephone ? FHIR::ContactPoint.new(system: 'phone',
                                                           value: patient.primary_telephone,
                                                           rank: 1,
                                                           extension: [to_string_extension(patient.primary_telephone_type, 'phone-type')])
                                  : nil,
        patient.secondary_telephone ? FHIR::ContactPoint.new(system: 'phone',
                                                             value: patient.secondary_telephone,
                                                             rank: 2,
                                                             extension: [to_string_extension(patient.secondary_telephone_type, 'phone-type')])
                                    : nil,
        patient.email ? FHIR::ContactPoint.new(system: 'email', value: patient.email, rank: 1) : nil
      ].reject(&:nil?),
      birthDate: patient.date_of_birth&.strftime('%F'),
      address: [to_address_by_type_extension(patient, 'USA'), to_address_by_type_extension(patient, 'Foreign')].reject(&:blank?),
      communication: [
        language_coding(patient.primary_language) ? FHIR::Patient::Communication.new(
          language: FHIR::CodeableConcept.new(coding: [language_coding(patient.primary_language)]),
          preferred: patient.interpretation_required
        ) : nil
      ].reject(&:nil?),
      extension: [
        to_us_core_race(races_as_hash(patient)),
        to_us_core_ethnicity(patient.ethnicity),
        to_us_core_birthsex(patient.sex),
        to_string_extension(patient.preferred_contact_method, 'preferred-contact-method'),
        to_string_extension(patient.preferred_contact_time, 'preferred-contact-time'),
        to_date_extension(patient.symptom_onset, 'symptom-onset-date'),
        to_date_extension(patient.last_date_of_exposure, 'last-date-of-exposure'),
        to_bool_extension(patient.isolation, 'isolation'),
        to_string_extension(patient.jurisdiction.jurisdiction_path_string, 'full-assigned-jurisdiction-path'),
        to_string_extension(patient.monitoring_plan, 'monitoring-plan'),
        to_positive_integer_extension(patient.assigned_user, 'assigned-user'),
        to_date_extension(patient.additional_planned_travel_start_date, 'additional-planned-travel-start-date'),
        to_string_extension(patient.port_of_origin, 'port-of-origin'),
        to_date_extension(patient.date_of_departure, 'date-of-departure'),
        to_string_extension(patient.flight_or_vessel_number, 'flight-or-vessel-number'),
        to_string_extension(patient.flight_or_vessel_carrier, 'flight-or-vessel-carrier'),
        to_date_extension(patient.date_of_arrival, 'date-of-arrival'),
        to_string_extension(patient.exposure_notes, 'exposure-notes'),
        to_string_extension(patient.travel_related_notes, 'travel-related-notes'),
        to_string_extension(patient.additional_planned_travel_related_notes, 'additional-planned-travel-notes'),
        to_bool_extension(patient.continuous_exposure, 'continuous-exposure')
      ].reject(&:nil?)
    )
  end

  def races_as_hash(patient)
    {
      white: patient.white,
      black_or_african_american: patient.black_or_african_american,
      american_indian_or_alaska_native: patient.american_indian_or_alaska_native,
      asian: patient.asian,
      native_hawaiian_or_other_pacific_islander: patient.native_hawaiian_or_other_pacific_islander,
      race_other: patient.race_other,
      race_unknown: patient.race_unknown,
      race_refused_to_answer: patient.race_refused_to_answer
    }
  end

  # Create a hash of atttributes that corresponds to a Sara Alert Patient (and can be used to
  # create new ones, or update existing ones), using the given FHIR::Patient.
  # Hash is of the form:
  # {
  #  attribute_name: { value: <converted-value>, path: <fhirpath-to-corresponding-fhir-element> }
  # }
  def patient_from_fhir(patient, default_jurisdiction_id)
    symptom_onset = from_date_extension(patient, 'Patient', ['symptom-onset-date'])
    foreign_address = from_address_by_type_extension(patient, 'Foreign')
    foreign_address_index = patient&.address&.index(foreign_address)
    address = from_address_by_type_extension(patient, 'USA')
    address_index = patient&.address&.index(address) || foreign_address_index || 0
    primary_phone = patient&.telecom&.find { |t| t&.system == 'phone' }
    secondary_phone = patient&.telecom&.select { |t| t&.system == 'phone' }&.second
    email = patient&.telecom&.find { |t| t&.system == 'email' }
    {
      monitoring: { value: patient&.active.nil? ? false : patient.active, path: 'Patient.active' },
      first_name: { value: patient&.name&.first&.given&.first, path: 'Patient.name[0].given[0]' },
      middle_name: { value: patient&.name&.first&.given&.second, path: 'Patient.name[0].given[1]' },
      last_name: { value: patient&.name&.first&.family, path: 'Patient.name[0].family' },
      primary_telephone: { value: from_fhir_phone_number(primary_phone&.value), path: "Patient.telecom[#{patient&.telecom&.index(primary_phone)}].value" },
      secondary_telephone: { value: from_fhir_phone_number(secondary_phone&.value),
                             path: "Patient.telecom[#{patient&.telecom&.index(secondary_phone)}].value" },
      email: { value: email&.value, path: "Patient.telecom[#{patient&.telecom&.index(email)}].value" },
      date_of_birth: { value: patient&.birthDate, path: 'Patient.birthDate' },
      age: { value: Patient.calc_current_age_fhir(patient&.birthDate), path: 'Patient.birthDate' },
      # foreign_address has to be mapped before address, because address_state has a validation rule that depends on foreign_address_country
      foreign_address_line_1: { value: foreign_address&.line&.first, path: "Patient.address[#{foreign_address_index}].line[0]" },
      foreign_address_line_2: { value: foreign_address&.line&.second, path: "Patient.address[#{foreign_address_index}].line[1]" },
      foreign_address_line_3: { value: foreign_address&.line&.third, path: "Patient.address[#{foreign_address_index}].line[2]" },
      foreign_address_city: { value: foreign_address&.city, path: "Patient.address[#{foreign_address_index}].city" },
      foreign_address_state: { value: foreign_address&.state, path: "Patient.address[#{foreign_address_index}].state" },
      foreign_address_zip: { value: foreign_address&.postalCode, path: "Patient.address[#{foreign_address_index}].postalCode" },
      foreign_address_country: { value: foreign_address&.country, path: "Patient.address[#{foreign_address_index}].country" },
      address_line_1: { value: address&.line&.first, path: "Patient.address[#{address_index}].line[0]" },
      address_line_2: { value: address&.line&.second, path: "Patient.address[#{address_index}].line[1]" },
      address_city: { value: address&.city, path: "Patient.address[#{address_index}].city" },
      address_county: { value: address&.district, path: "Patient.address[#{address_index}].district" },
      address_state: { value: address&.state, path: "Patient.address[#{address_index}].state" },
      address_zip: { value: address&.postalCode, path: "Patient.address[#{address_index}].postalCode" },
      monitored_address_line_1: { value: address&.line&.first, path: "Patient.address[#{address_index}].line[0]" },
      monitored_address_line_2: { value: address&.line&.second, path: "Patient.address[#{address_index}].line[1]" },
      monitored_address_city: { value: address&.city, path: "Patient.address[#{address_index}].city" },
      monitored_address_county: { value: address&.district, path: "Patient.address[#{address_index}].district" },
      monitored_address_state: { value: address&.state, path: "Patient.address[#{address_index}].state" },
      monitored_address_zip: { value: address&.postalCode, path: "Patient.address[#{address_index}].postalCode" },
      primary_language: { value: patient&.communication&.first&.language&.coding&.first&.display, path: 'Patient.communication[0].language.coding[0].display' },
      interpretation_required: { value: patient&.communication&.first&.preferred, path: 'Patient.communication[0].preferred' },
      white: race_code?(patient, '2106-3', OMB_URL),
      black_or_african_american: race_code?(patient, '2054-5', OMB_URL),
      american_indian_or_alaska_native: race_code?(patient, '1002-5', OMB_URL),
      asian: race_code?(patient, '2028-9', OMB_URL),
      native_hawaiian_or_other_pacific_islander: race_code?(patient, '2076-8', OMB_URL),
      race_other: race_code?(patient, '2131-1', DETAILED_URL),
      race_unknown: race_code?(patient, 'unknown', DATA_ABSENT_URL),
      race_refused_to_answer: race_code?(patient, 'asked-declined', DATA_ABSENT_URL),
      ethnicity: from_us_core_ethnicity(patient),
      sex: from_us_core_birthsex(patient),
      preferred_contact_method: from_string_extension(patient, 'Patient', 'preferred-contact-method'),
      preferred_contact_time: from_string_extension(patient, 'Patient', 'preferred-contact-time'),
      symptom_onset: symptom_onset,
      user_defined_symptom_onset: { value: !symptom_onset[:value]&.nil?, path: date_ext_path('Patient', 'symptom-onset-date') },
      last_date_of_exposure: from_date_extension(patient, 'Patient', %w[last-date-of-exposure last-exposure-date]),
      isolation: from_bool_extension_false_default(patient, 'Patient', 'isolation'),
      jurisdiction_id: from_full_assigned_jurisdiction_path_extension(patient, 'Patient', default_jurisdiction_id),
      monitoring_plan: from_string_extension(patient, 'Patient', 'monitoring-plan'),
      assigned_user: from_positive_integer_extension(patient, 'Patient', 'assigned-user'),
      additional_planned_travel_start_date: from_date_extension(patient, 'Patient', ['additional-planned-travel-start-date']),
      port_of_origin: from_string_extension(patient, 'Patient', 'port-of-origin'),
      date_of_departure: from_date_extension(patient, 'Patient', ['date-of-departure']),
      flight_or_vessel_number: from_string_extension(patient, 'Patient', 'flight-or-vessel-number'),
      flight_or_vessel_carrier: from_string_extension(patient, 'Patient', 'flight-or-vessel-carrier'),
      date_of_arrival: from_date_extension(patient, 'Patient', ['date-of-arrival']),
      exposure_notes: from_string_extension(patient, 'Patient', 'exposure-notes'),
      travel_related_notes: from_string_extension(patient, 'Patient', 'travel-related-notes'),
      additional_planned_travel_related_notes: from_string_extension(patient, 'Patient', 'additional-planned-travel-notes'),
      primary_telephone_type: from_primary_phone_type_extension(patient, 'Patient'),
      secondary_telephone_type: from_secondary_phone_type_extension(patient, 'Patient'),
      user_defined_id_statelocal: from_statelocal_id_extension(patient, 'Patient'),
      continuous_exposure: from_bool_extension_false_default(patient, 'Patient', 'continuous-exposure')
    }
  end

  def close_contact_as_fhir(close_contact)
    FHIR::RelatedPerson.new(
      meta: FHIR::Meta.new(lastUpdated: close_contact.updated_at.strftime('%FT%T%:z')),
      id: close_contact.id,
      name: [FHIR::HumanName.new(given: [close_contact.first_name].reject(&:blank?), family: close_contact.last_name)],
      telecom: [
        close_contact.primary_telephone ? FHIR::ContactPoint.new(system: 'phone',
                                                                 value: close_contact.primary_telephone,
                                                                 rank: 1)
                                  : nil,
        close_contact.email ? FHIR::ContactPoint.new(system: 'email', value: close_contact.email, rank: 1) : nil
      ].reject(&:nil?),
      patient: FHIR::Reference.new(reference: "Patient/#{close_contact.patient_id}"),
      extension: [
        to_date_extension(close_contact.last_date_of_exposure, 'last-date-of-exposure'),
        to_positive_integer_extension(close_contact.assigned_user, 'assigned-user'),
        to_unsigned_integer_extension(close_contact.contact_attempts, 'contact-attempts'),
        to_string_extension(close_contact.notes, 'notes'),
        to_reference_extension(close_contact.enrolled_id, 'Patient', 'enrolled-patient')
      ]
    )
  end

  def close_contact_from_fhir(related_person)
    phone = related_person&.telecom&.find { |t| t&.system == 'phone' }
    email = related_person&.telecom&.find { |t| t&.system == 'email' }
    {
      first_name: { value: related_person&.name&.first&.given&.first, path: 'RelatedPerson.name[0].given[0]' },
      last_name: { value: related_person&.name&.first&.family, path: 'RelatedPerson.name[0].family' },
      primary_telephone: { value: from_fhir_phone_number(phone&.value), path: "RelatedPerson.telecom[#{related_person&.telecom&.index(phone)}].value" },
      email: { value: email&.value, path: "RelatedPerson.telecom[#{related_person&.telecom&.index(email)}].value" },
      last_date_of_exposure: from_date_extension(related_person, 'RelatedPerson', %w[last-date-of-exposure last-exposure-date]),
      assigned_user: from_positive_integer_extension(related_person, 'RelatedPerson', 'assigned-user'),
      notes: from_string_extension(related_person, 'RelatedPerson', 'notes'),
      patient_id: { value: related_person&.patient&.reference&.match(%r{^Patient/(\d+)$}).to_a[1], path: 'RelatedPerson.patient.reference' },
      contact_attempts: from_unsigned_integer_extension_0_default(related_person, 'RelatedPerson', 'contact-attempts')
    }
  end

  # Build a FHIR US Core Race Extension given Sara Alert race booleans.
  def to_us_core_race(races)
    # Don't return an extension if all race categories are false or nil
    return nil unless races.values.include?(true)

    # Build out extension based on what race categories are true
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race', extension: [
      races[:white] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2106-3', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'White')
      ) : nil,
      races[:black_or_african_american] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2054-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Black or African American')
      ) : nil,
      races[:american_indian_or_alaska_native] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '1002-5', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'American Indian or Alaska Native')
      ) : nil,
      races[:asian] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2028-9', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Asian')
      ) : nil,
      races[:native_hawaiian_or_other_pacific_islander] ? FHIR::Extension.new(
        url: 'ombCategory',
        valueCoding: FHIR::Coding.new(code: '2076-8', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Native Hawaiian or Other Pacific Islander')
      ) : nil,
      races[:race_other] ? FHIR::Extension.new(
        url: 'detailed',
        valueCoding: FHIR::Coding.new(code: '2131-1', system: 'urn:oid:2.16.840.1.113883.6.238', display: 'Other Race')
      ) : nil,
      races[:race_unknown] ? FHIR::Extension.new(
        url: DATA_ABSENT_URL,
        valueCode: 'unknown'
      ) : nil,
      races[:race_refused_to_answer] ? FHIR::Extension.new(
        url: DATA_ABSENT_URL,
        valueCode: 'asked-declined'
      ) : nil,
      FHIR::Extension.new(
        url: 'text',
        valueString: [races[:white] ? 'White' : nil,
                      races[:black_or_african_american] ? 'Black or African American' : nil,
                      races[:american_indian_or_alaska_native] ? 'American Indian or Alaska Native' : nil,
                      races[:asian] ? 'Asian' : nil,
                      races[:native_hawaiian_or_other_pacific_islander] ? 'Native Hawaiian or Other Pacific Islander' : nil,
                      races[:race_unknown] ? 'Unknown' : nil,
                      races[:race_other] ? 'Other' : nil,
                      races[:race_refused_to_answer] ? 'Refused to Answer' : nil].reject(&:nil?).join(', ')
      )
    ].reject(&:nil?))
  end

  # Determine if the given race code is present on the given FHIR::Patient.
  def race_code?(patient, code, url)
    race_url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race'
    race_ext = patient&.extension&.find { |e| e.url == race_url }

    case url
    when OMB_URL, DETAILED_URL
      value = race_ext&.extension&.find { |e| e.url == url && e.valueCoding&.code == code }&.valueCoding&.code
      path_suffix = '.valueCoding.code'
    when DATA_ABSENT_URL
      value = race_ext&.extension&.find { |e| e.url == DATA_ABSENT_URL }&.valueCode
      path_suffix = '.valueCode'
    end

    { value: value == code, path: "Patient.extension('#{race_url}').extension('#{url}')#{path_suffix}" }
  end

  # Build a FHIR US Core Ethnicity Extension given Sara Alert ethnicity information.
  def to_us_core_ethnicity(ethnicity)
    # Don't return an extension if no ethnicity specified
    return nil unless ValidationHelper::VALID_PATIENT_ENUMS[:ethnicity].include?(ethnicity)

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
                          ethnicity == 'Unknown' ? FHIR::Extension.new(
                            url: DATA_ABSENT_URL,
                            valueCode: 'unknown'
                          ) : nil,
                          ethnicity == 'Refused to Answer' ? FHIR::Extension.new(
                            url: DATA_ABSENT_URL,
                            valueCode: 'asked-declined'
                          ) : nil,
                          FHIR::Extension.new(
                            url: 'text',
                            valueString: ethnicity
                          )
                        ])
  end

  # Convert from FHIR ethnicity. Could be ombCategory or a data-absent-reason
  def from_us_core_ethnicity(patient)
    eth_url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity'
    eth_ext = patient&.extension&.find { |e| e.url == eth_url }
    omb_eth = eth_ext&.extension&.find { |e| e.url == OMB_URL }&.valueCoding&.code
    absent_eth = eth_ext&.extension&.find { |e| e.url == DATA_ABSENT_URL }&.valueCode
    if omb_eth
      converted = 'Hispanic or Latino' if omb_eth == '2135-2'
      converted = 'Not Hispanic or Latino' if omb_eth == '2186-5'
      path_suffix = ".extension('#{OMB_URL}').valueCoding.code"
    elsif absent_eth
      converted = 'Unknown' if absent_eth == 'unknown'
      converted = 'Refused to Answer' if absent_eth == 'asked-declined'
      path_suffix = ".extension('#{DATA_ABSENT_URL}').valueCode"
    end

    { value: converted || omb_eth || absent_eth, path: "Patient.extension('#{eth_url}')#{path_suffix}" }
  end

  # Build a FHIR US Core BirthSex Extension given Sara Alert sex information.
  def to_us_core_birthsex(sex)
    # Don't return an extension if no sex specified
    return nil unless %w[Male Female Unknown].include?(sex)

    # Build out extension based on what sex was specified
    code = sex == 'Unknown' ? 'UNK' : sex.first
    FHIR::Extension.new(url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex', valueCode: code)
  end

  # Return a string representing the birthsex of the given FHIR::Patient
  def from_us_core_birthsex(patient)
    url = 'us-core-birthsex'
    code = patient&.extension&.select { |e| e.url.include?(url) }&.first&.valueCode
    converted = 'Male' if code == 'M'
    converted = 'Female' if code == 'F'
    converted = 'Unknown' if code == 'UNK'

    { value: converted || code, path: "Patient.extension('http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex').valueCode" }
  end

  # Given a language string, try to find the corresponding BCP 47 code for it and construct a FHIR::Coding.
  def language_coding(language)
    PatientHelper.languages(language&.downcase) ? FHIR::Coding.new(**PatientHelper.languages(language&.downcase)) : nil
  end

  def to_bool_extension(value, extension_id)
    value.nil? ? nil : FHIR::Extension.new(
      url: SA_EXT_BASE_URL + extension_id,
      valueBoolean: value
    )
  end

  # Convert from a boolean extension, treating omission (nil) as equal to false
  def from_bool_extension_false_default(element, base_path, extension_id)
    { value: element&.extension&.find { |e| e.url.include?(extension_id) }&.valueBoolean || false, path: bool_ext_path(base_path, extension_id) }
  end

  def to_date_extension(value, extension_id)
    value.nil? ? nil : FHIR::Extension.new(
      url: SA_EXT_BASE_URL + extension_id,
      valueDate: value
    )
  end

  # Check for multiple extension IDs for the sake of backwards compatibility with IDs that have changed
  def from_date_extension(element, base_path, extension_ids)
    val = nil
    ext_id = nil
    extension_ids.each do |eid|
      val = element&.extension&.find { |e| e.url.include?(eid) }&.valueDate
      ext_id = eid
      break unless val.nil?
    end
    { value: val, path: date_ext_path(base_path, ext_id) }
  end

  def to_string_extension(value, extension_id)
    value.nil? || value.empty? ? nil : FHIR::Extension.new(
      url: SA_EXT_BASE_URL + extension_id,
      valueString: value
    )
  end

  def from_string_extension(element, base_path, extension_id)
    { value: element&.extension&.find { |e| e.url.include?(extension_id) }&.valueString, path: str_ext_path(base_path, extension_id) }
  end

  def to_reference_extension(id, resource_type, extension_id)
    id.blank? ? nil : FHIR::Extension.new(
      url: "http://saraalert.org/StructureDefinition/#{extension_id}",
      valueReference: FHIR::Reference.new(reference: "#{resource_type}/#{id}")
    )
  end

  def to_positive_integer_extension(value, extension_id)
    value.nil? ? nil : FHIR::Extension.new(
      url: SA_EXT_BASE_URL + extension_id,
      valuePositiveInt: value
    )
  end

  def from_positive_integer_extension(element, base_path, extension_id)
    { value: element&.extension&.find { |e| e.url.include?(extension_id) }&.valuePositiveInt, path: pos_int_ext_path(base_path, extension_id) }
  end

  def to_unsigned_integer_extension(value, extension_id)
    value.nil? ? nil : FHIR::Extension.new(
      url: "http://saraalert.org/StructureDefinition/#{extension_id}",
      valueUnsignedInt: value
    )
  end

  def from_unsigned_integer_extension_0_default(element, base_path, extension_id)
    { value: element&.extension&.find { |e| e.url.include?(extension_id) }&.valueUnsignedInt || 0, path: unsigned_int_ext_path(base_path, extension_id) }
  end

  # Convert from FHIR extension for Full Assigned Jurisdiction Path.
  # Use the default if there is no path specified.
  def from_full_assigned_jurisdiction_path_extension(element, base_path, default_jurisdiction_id)
    jurisdiction_path_hash = from_string_extension(element, base_path, 'full-assigned-jurisdiction-path')
    jurisdiction_path_hash[:value] = Jurisdiction.find_by(path: jurisdiction_path_hash[:value])&.id || default_jurisdiction_id
    jurisdiction_path_hash
  end

  # element must be a FHIR element with a telecom array
  def from_primary_phone_type_extension(element, base_path)
    phone_telecom = element&.telecom&.find { |t| t&.system == 'phone' }
    {
      value: phone_telecom&.extension&.find { |e| e.url.include?('phone-type') }&.valueString,
      path: str_ext_path("#{base_path}.telecom[#{element&.telecom&.index(phone_telecom)}]", 'phone-type')
    }
  end

  # element must be a FHIR element with a telecom array
  def from_secondary_phone_type_extension(element, base_path)
    phone_telecom = element&.telecom&.select { |t| t&.system == 'phone' }&.second
    {
      value: phone_telecom&.extension&.find { |e| e.url.include?('phone-type') }&.valueString,
      path: str_ext_path("#{base_path}.telecom[#{element&.telecom&.index(phone_telecom)}]", 'phone-type')
    }
  end

  def from_fhir_phone_number(value)
    Phonelib.parse(value, 'US').full_e164.presence || value
  end

  def to_statelocal_identifier(statelocal_identifier)
    FHIR::Identifier.new(value: statelocal_identifier, system: 'http://saraalert.org/SaraAlert/state-local-id') unless statelocal_identifier.blank?
  end

  def from_statelocal_id_extension(element, base_path)
    statelocal_id = element&.identifier&.find { |i| i&.system == 'http://saraalert.org/SaraAlert/state-local-id' }
    { value: statelocal_id&.value, path: "#{base_path}.identifier[#{element&.identifier&.index(statelocal_id)}].value" }
  end

  def to_address_by_type_extension(patient, address_type)
    case address_type
    when 'USA'
      FHIR::Address.new(
        line: [patient.address_line_1, patient.address_line_2].reject(&:blank?),
        city: patient.address_city,
        district: patient.address_county,
        state: patient.address_state,
        postalCode: patient.address_zip
      )
    when 'Foreign'
      [patient.foreign_address_line_1,
       patient.foreign_address_line_2,
       patient.foreign_address_line_3,
       patient.foreign_address_city,
       patient.foreign_address_country,
       patient.foreign_address_zip,
       patient.foreign_address_state].any? ?
      FHIR::Address.new(
        line: [patient.foreign_address_line_1, patient.foreign_address_line_2, patient.foreign_address_line_3].reject(&:blank?),
        city: patient.foreign_address_city,
        country: patient.foreign_address_country,
        state: patient.foreign_address_state,
        postalCode: patient.foreign_address_zip,
        extension: [FHIR::Extension.new(url: "#{SA_EXT_BASE_URL}address-type", valueString: 'Foreign')]
      ) : nil
    end
  end

  def from_address_by_type_extension(element, address_type)
    address = element&.address&.find do |a|
      a.extension&.any? { |e| e.url == "#{SA_EXT_BASE_URL}address-type" && e.valueString == address_type }
    end

    if address.nil? && address_type == 'USA'
      address = element&.address&.find do |a|
        a.extension&.all? { |e| e.url != "#{SA_EXT_BASE_URL}address-type" }
      end
    end

    address
  end

  def str_ext_path(base_path, ext_id)
    "#{base_path}.extension('#{SA_EXT_BASE_URL + ext_id}').valueString"
  end

  def bool_ext_path(base_path, ext_id)
    "#{base_path}.extension('#{SA_EXT_BASE_URL + ext_id}').valueBoolean"
  end

  def pos_int_ext_path(base_path, ext_id)
    "#{base_path}.extension('#{SA_EXT_BASE_URL + ext_id}').valuePositiveInt"
  end

  def unsigned_int_ext_path(base_path, ext_id)
    "#{base_path}.extension('#{SA_EXT_BASE_URL + ext_id}').valueUnsignedInt"
  end

  def date_ext_path(base_path, ext_id)
    "#{base_path}.extension('#{SA_EXT_BASE_URL + ext_id}').valueDate"
  end
end
