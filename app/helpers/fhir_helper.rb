# frozen_string_literal: true

# Helper module for FHIR translations
module FhirHelper # rubocop:todo Metrics/ModuleLength
  SA_EXT_BASE_URL = 'http://saraalert.org/StructureDefinition/'
  DATA_ABSENT_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'
  OMB_URL = 'ombCategory'
  DETAILED_URL = 'detailed'
  INTERPRETER_URL = 'http://hl7.org/fhir/StructureDefinition/patient-interpreterRequired'
  GENDER_IDENTITY_TO_FHIR = Rails.configuration.api['gender_identity']
  GENDER_IDENTITY_FROM_FHIR = GENDER_IDENTITY_TO_FHIR.invert
  SEXUAL_ORIENTATION_TO_FHIR = Rails.configuration.api['sexual_orientation']
  SEXUAL_ORIENTATION_FROM_FHIR = SEXUAL_ORIENTATION_TO_FHIR.invert

  # Switch the context of the paths on a fhir_map from old_context to new_context. For example
  # A Patient resource may have paths such as Patient.birthDate, but if that Patient resource
  # actually exists in an array of Bundle entries, the correct path is Bundle.entry[<index>].birthDate
  def change_fhir_map_context!(fhir_map, old_context, new_context)
    fhir_map.transform_values! { |v| { path: v[:path].sub(old_context, new_context), value: v[:value], errors: v[:errors] } }
  end

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
      identifier: [
        to_identifier(patient.user_defined_id_statelocal, 'state-local-id'),
        to_identifier(patient.user_defined_id_cdc, 'cdc-id'),
        to_identifier(patient.user_defined_id_nndss, 'nndss-id')
      ],
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
      address: [
        to_address_by_type_extension(patient, 'USA'),
        to_address_by_type_extension(patient, 'Foreign'),
        to_address_by_type_extension(patient, 'Monitored'),
        to_address_by_type_extension(patient, 'ForeignMonitored')
      ].reject(&:blank?),
      communication: [
        to_communication(patient.primary_language, true),
        to_communication(patient.secondary_language, false)
      ].reject(&:nil?),
      extension: [
        to_us_core_race(races_as_hash(patient)),
        to_us_core_ethnicity(patient.ethnicity),
        to_us_core_birthsex(patient.sex),
        *patient.transfers.map { |t| transfer_as_fhir_extension(t) },
        to_exposure_risk_factors_extension(patient),
        to_report_source_extension(patient),
        to_string_extension(patient.preferred_contact_method, 'preferred-contact-method'),
        to_string_extension(patient.preferred_contact_time, 'preferred-contact-time'),
        to_date_extension(patient.symptom_onset, 'symptom-onset-date'),
        to_date_extension(patient.last_date_of_exposure, 'last-date-of-exposure'),
        to_bool_extension(patient.isolation, 'isolation'),
        to_string_extension(patient.jurisdiction[:path], 'full-assigned-jurisdiction-path'),
        to_string_extension(patient.monitoring_plan, 'monitoring-plan'),
        to_positive_integer_extension(patient.assigned_user, 'assigned-user'),
        to_date_extension(patient.additional_planned_travel_start_date, 'additional-planned-travel-start-date'),
        to_date_extension(patient.additional_planned_travel_end_date, 'additional-planned-travel-end-date'),
        to_string_extension(patient.additional_planned_travel_related_notes, 'additional-planned-travel-notes'),
        to_string_extension(patient.additional_planned_travel_destination, 'additional-planned-travel-destination'),
        to_string_extension(patient.additional_planned_travel_destination_state, 'additional-planned-travel-destination-state'),
        to_string_extension(patient.additional_planned_travel_destination_country, 'additional-planned-travel-destination-country'),
        to_string_extension(patient.additional_planned_travel_port_of_departure, 'additional-planned-travel-port-of-departure'),
        to_string_extension(patient.additional_planned_travel_type, 'additional-planned-travel-type'),
        to_string_extension(patient.port_of_origin, 'port-of-origin'),
        to_string_extension(patient.port_of_entry_into_usa, 'port-of-entry-into-usa'),
        to_date_extension(patient.date_of_departure, 'date-of-departure'),
        to_string_extension(patient.flight_or_vessel_number, 'flight-or-vessel-number'),
        to_string_extension(patient.flight_or_vessel_carrier, 'flight-or-vessel-carrier'),
        to_date_extension(patient.date_of_arrival, 'date-of-arrival'),
        to_string_extension(patient.exposure_notes, 'exposure-notes'),
        to_string_extension(patient.travel_related_notes, 'travel-related-notes'),
        to_bool_extension(patient.continuous_exposure, 'continuous-exposure'),
        to_string_extension(patient.end_of_monitoring, 'end-of-monitoring'),
        to_datetime_extension(patient.expected_purge_ts, 'expected-purge-date'),
        to_string_extension(patient.exposure_risk_assessment, 'exposure-risk-assessment'),
        to_string_extension(patient.public_health_action, 'public-health-action'),
        to_string_extension(patient.potential_exposure_location, 'potential-exposure-location'),
        to_string_extension(patient.potential_exposure_country, 'potential-exposure-country'),
        to_interpreter_required_extension(patient.interpretation_required),
        to_date_extension(patient.extended_isolation, 'extended-isolation'),
        to_string_extension(patient.monitoring_reason, 'reason-for-closure'),
        to_string_extension(patient.follow_up_reason, 'follow-up-reason'),
        to_string_extension(patient.follow_up_note, 'follow-up-note'),
        to_string_extension(patient.case_status, 'case-status'),
        to_datetime_extension(patient.closed_at, 'closed-at'),
        to_gender_identity_extension(patient.gender_identity),
        to_sexual_orientation_extension(patient.sexual_orientation),
        to_bool_extension(patient.head_of_household, 'head-of-household'),
        to_positive_integer_extension(patient.responder_id, 'id-of-reporter'),
        to_datetime_extension(patient.last_assessment_reminder_sent, 'last-assessment-reminder-sent'),
        to_bool_extension(patient.pause_notifications, 'paused-notifications'),
        to_string_extension(patient.status_as_string, 'status'),
        to_bool_extension(patient.user_defined_symptom_onset, 'user-defined-symptom-onset')
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
    foreign_address_index = patient&.address&.index(foreign_address) || 0
    foreign_monitored_address = from_address_by_type_extension(patient, 'ForeignMonitored')
    foreign_monitored_address_index = patient&.address&.index(foreign_monitored_address) || 0
    monitored_address = from_address_by_type_extension(patient, 'Monitored')
    monitored_address_index = patient&.address&.index(monitored_address) || 0
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
      foreign_monitored_address_line_1: { value: foreign_monitored_address&.line&.first, path: "Patient.address[#{foreign_monitored_address_index}].line[0]" },
      foreign_monitored_address_line_2: { value: foreign_monitored_address&.line&.second, path: "Patient.address[#{foreign_monitored_address_index}].line[1]" },
      foreign_monitored_address_city: { value: foreign_monitored_address&.city, path: "Patient.address[#{foreign_monitored_address_index}].city" },
      foreign_monitored_address_county: { value: foreign_monitored_address&.district, path: "Patient.address[#{foreign_monitored_address_index}].district" },
      foreign_monitored_address_state: { value: foreign_monitored_address&.state, path: "Patient.address[#{foreign_monitored_address_index}].state" },
      foreign_monitored_address_zip: { value: foreign_monitored_address&.postalCode, path: "Patient.address[#{foreign_monitored_address_index}].postalCode" },
      monitored_address_line_1: { value: monitored_address&.line&.first, path: "Patient.address[#{monitored_address_index}].line[0]" },
      monitored_address_line_2: { value: monitored_address&.line&.second, path: "Patient.address[#{monitored_address_index}].line[1]" },
      monitored_address_city: { value: monitored_address&.city, path: "Patient.address[#{monitored_address_index}].city" },
      monitored_address_county: { value: monitored_address&.district, path: "Patient.address[#{monitored_address_index}].district" },
      monitored_address_state: { value: monitored_address&.state, path: "Patient.address[#{monitored_address_index}].state" },
      monitored_address_zip: { value: monitored_address&.postalCode, path: "Patient.address[#{monitored_address_index}].postalCode" },
      primary_language: from_communication(patient&.communication, 0),
      secondary_language: from_communication(patient&.communication, 1),
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
      user_defined_id_statelocal: from_identifier(patient&.identifier, 'state-local-id', 'Patient'),
      user_defined_id_cdc: from_identifier(patient&.identifier, 'cdc-id', 'Patient'),
      user_defined_id_nndss: from_identifier(patient&.identifier, 'nndss-id', 'Patient'),
      interpretation_required: from_interpreter_required_extension(patient, 'Patient'),
      last_date_of_exposure: from_date_extension(patient, 'Patient', %w[last-date-of-exposure last-exposure-date]),
      isolation: from_bool_extension_false_default(patient, 'Patient', 'isolation'),
      jurisdiction_id: from_full_assigned_jurisdiction_path_extension(patient, 'Patient', default_jurisdiction_id),
      monitoring_plan: from_string_extension(patient, 'Patient', 'monitoring-plan'),
      assigned_user: from_positive_integer_extension(patient, 'Patient', 'assigned-user'),
      additional_planned_travel_start_date: from_date_extension(patient, 'Patient', ['additional-planned-travel-start-date']),
      additional_planned_travel_end_date: from_date_extension(patient, 'Patient', ['additional-planned-travel-end-date']),
      additional_planned_travel_destination: from_string_extension(patient, 'Patient', 'additional-planned-travel-destination'),
      additional_planned_travel_destination_state: from_string_extension(patient, 'Patient', 'additional-planned-travel-destination-state'),
      additional_planned_travel_destination_country: from_string_extension(patient, 'Patient', 'additional-planned-travel-destination-country'),
      additional_planned_travel_port_of_departure: from_string_extension(patient, 'Patient', 'additional-planned-travel-port-of-departure'),
      additional_planned_travel_type: from_string_extension(patient, 'Patient', 'additional-planned-travel-type'),
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
      continuous_exposure: from_bool_extension_false_default(patient, 'Patient', 'continuous-exposure'),
      exposure_risk_assessment: from_string_extension(patient, 'Patient', 'exposure-risk-assessment'),
      public_health_action: from_string_extension(patient, 'Patient', 'public-health-action', 'None'),
      potential_exposure_location: from_string_extension(patient, 'Patient', 'potential-exposure-location'),
      potential_exposure_country: from_string_extension(patient, 'Patient', 'potential-exposure-country'),
      extended_isolation: from_date_extension(patient, 'Patient', ['extended-isolation']),
      follow_up_reason: from_string_extension(patient, 'Patient', 'follow-up-reason'),
      follow_up_note: from_string_extension(patient, 'Patient', 'follow-up-note'),
      port_of_entry_into_usa: from_string_extension(patient, 'Patient', 'port-of-entry-into-usa'),
      case_status: from_string_extension(patient, 'Patient', 'case-status'),
      gender_identity: from_gender_identity_extension(patient, 'Patient'),
      sexual_orientation: from_sexual_orientation_extension(patient, 'Patient'),
      **from_exposure_risk_factors_extension(patient),
      **from_report_source_extension(patient)
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
        to_reference_extension(close_contact.enrolled_id, 'Patient', 'enrolled-patient'),
        to_datetime_extension(close_contact.created_at, 'created-at')
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

  # Returns a representative FHIR::Provenance for an instance of a Sara Alert History.
  # https://www.hl7.org/fhir/provenance.html
  def history_as_fhir(history)
    FHIR::Provenance.new(
      contained: history.deleted_by.nil? ? nil : [
        FHIR::Provenance.new(
          target: [FHIR::Reference.new(reference: "Provenance/#{history.id}")],
          agent: [
            FHIR::Provenance::Agent.new(
              who: FHIR::Reference.new(identifier: FHIR::Identifier.new(value: history.deleted_by))
            )
          ],
          recorded: history.updated_at.strftime('%FT%T%:z'),
          reason: FHIR::CodeableConcept.new(
            text: history.delete_reason
          ),
          activity: {
            coding: [
              {
                system: 'http://terminology.hl7.org/CodeSystem/v3-DataOperation',
                code: 'DELETE',
                display: 'delete'
              }
            ]
          }
        )
      ],
      meta: FHIR::Meta.new(lastUpdated: history.updated_at.strftime('%FT%T%:z')),
      id: history.id,
      target: FHIR::Reference.new(reference: "Patient/#{history.patient_id}"),
      recorded: history.created_at.strftime('%FT%T%:z'),
      agent: [
        {
          who: FHIR::Reference.new(identifier: FHIR::Identifier.new(value: history.created_by)),
          onBehalfOf: FHIR::Reference.new(reference: "Patient/#{history.patient_id}")
        }
      ],
      extension: [
        to_string_extension(history.comment, 'comment'),
        to_string_extension(history.history_type, 'history-type'),
        to_positive_integer_extension(history.original_comment_id, 'original-id')
      ]
    )
  end

  # Returns a representative FHIR::Immunization for an instance of a Sara Alert Vaccine.
  # https://www.hl7.org/fhir/immunization.html
  def vaccine_as_fhir(vaccine)
    FHIR::Immunization.new(
      meta: FHIR::Meta.new(lastUpdated: vaccine.updated_at.strftime('%FT%T%:z')),
      id: vaccine.id,
      status: 'completed',
      vaccineCode: [
        FHIR::CodeableConcept.new(
          text: vaccine.product_name,
          coding: Vaccine.product_codes_by_name(vaccine.group_name, vaccine.product_name).map do |code|
            FHIR::Coding.new(code: code['code'], system: code['system'])
          end
        )
      ],
      patient: FHIR::Reference.new(reference: "Patient/#{vaccine.patient_id}"),
      occurrenceDateTime: vaccine.administration_date,
      note: FHIR::Annotation.new(text: vaccine.notes),
      protocolApplied: [
        {
          targetDisease: [
            FHIR::CodeableConcept.new(
              text: vaccine.group_name,
              coding: Vaccine.group_codes_by_name(vaccine.group_name).map do |code|
                FHIR::Coding.new(code: code['code'], system: code['system'])
              end
            )
          ],
          doseNumberString: vaccine.dose_number
        }
      ],
      extension: [
        to_datetime_extension(vaccine.created_at, 'created-at')
      ]
    )
  end

  # Create a hash of atttributes that corresponds to a Sara Alert Vaccine (and can be used to
  # create new ones, or update existing ones), using the given FHIR::Immunization.
  # Hash is of the form:
  # {
  #  attribute_name: { value: <converted-value>, path: <fhirpath-to-corresponding-fhir-element>, errors: <array-of-messages> }
  # }
  def vaccine_from_fhir(vaccine)
    group_coding = vaccine&.protocolApplied&.first&.targetDisease&.first&.coding&.first
    group = Vaccine.group_name_by_code(group_coding&.system, group_coding&.code)
    if group.nil? && !group_coding.nil?
      group_errors = ["is not an acceptable value, acceptable values are: #{Vaccine.group_code_options.map do |c|
                                                                              pretty_print_code_from_fhir(c)
                                                                            end.join(', ')}"]
    end

    product_name_coding = vaccine&.vaccineCode&.first&.coding&.first
    product_name = Vaccine.product_name_by_code(group, product_name_coding&.system, product_name_coding&.code)
    if product_name.nil? && !product_name_coding.nil? && group_errors.nil?
      product_name_errors = ["is not an acceptable value, acceptable values are: #{Vaccine.product_code_options(group).map do |c|
                                                                                     pretty_print_code_from_fhir(c)
                                                                                   end.join(', ')}"]
    end

    {
      group_name: { value: group, path: 'Immunization.protocolApplied[0].targetDisease[0].coding[0]', errors: group_errors },
      product_name: { value: product_name, path: 'Immunization.vaccineCode[0].coding[0]', errors: product_name_errors },
      administration_date: { value: vaccine&.occurrenceDateTime, path: 'Immunization.occurrenceDateTime' },
      dose_number: { value: vaccine&.protocolApplied&.first&.doseNumberString, path: 'Immunization.protocolApplied[0].doseNumberString' },
      notes: { value: vaccine&.note&.first&.text, path: 'Immunization.note[0].text' },
      patient_id: { value: vaccine&.patient&.reference&.match(%r{^Patient/(\d+)$}).to_a[1], path: 'Immunization.patient.reference' }
    }
  end

  # Returns a representative FHIR::Observation for an instance of a Sara Alert Laboratory.
  # https://www.hl7.org/fhir/observation.html
  def laboratory_as_fhir(laboratory)
    coded_lab_type = Laboratory.lab_type_to_code(laboratory.lab_type)
    coded_result = Laboratory.result_to_code(laboratory.result)

    FHIR::Observation.new(
      meta: FHIR::Meta.new(lastUpdated: laboratory.updated_at.strftime('%FT%T%:z')),
      id: laboratory.id,
      status: 'final',
      category: [
        FHIR::CodeableConcept.new(
          coding: [
            FHIR::Coding.new(
              system: 'http://terminology.hl7.org/CodeSystem/observation-category',
              code: 'laboratory'
            )
          ]
        )
      ],
      code: FHIR::CodeableConcept.new(
        text: laboratory.lab_type,
        coding: [
          FHIR::Coding.new(
            system: coded_lab_type[:system],
            code: coded_lab_type[:code]
          )
        ]
      ),
      subject: FHIR::Reference.new(reference: "Patient/#{laboratory.patient_id}"),
      effectiveDateTime: laboratory.specimen_collection,
      issued: laboratory.report&.strftime('%FT%T%:z'),
      valueCodeableConcept: coded_result.nil? ? nil : FHIR::CodeableConcept.new(
        text: laboratory.result,
        coding: [
          FHIR::Coding.new(
            system: coded_result[:system],
            code: coded_result[:code]
          )
        ]
      ),
      extension: [
        to_datetime_extension(laboratory.created_at, 'created-at')
      ]
    )
  end

  # Create a hash of atttributes that corresponds to a Sara Alert Laboratory (and can be used to
  # create new ones, or update existing ones), using the given FHIR::Observation.
  # Hash is of the form:
  # {
  #  attribute_name: { value: <converted-value>, path: <fhirpath-to-corresponding-fhir-element>, errors: <array-of-messages> }
  # }
  def laboratory_from_fhir(observation)
    result_coding = observation&.valueCodeableConcept&.coding&.first
    result = Laboratory.code_to_result(result_coding&.system, result_coding&.code)
    if result.nil? && !result_coding.nil?
      result_errors = ["is not an acceptable value, acceptable values are: #{Laboratory::CODE_TO_RESULT.keys.map do |c|
                                                                               pretty_print_code_from_fhir(c.stringify_keys)
                                                                             end.join(', ')}"]
    end

    lab_type_coding = observation&.code&.coding&.first
    lab_type = Laboratory.code_to_lab_type(lab_type_coding&.system, lab_type_coding&.code)
    if lab_type.nil? && !lab_type_coding.nil?
      lab_type_errors = ["is not an acceptable value, acceptable values are: #{Laboratory::CODE_TO_LAB_TYPE.keys.map do |c|
                                                                                 pretty_print_code_from_fhir(c.stringify_keys)
                                                                               end.join(', ')}"]
    end

    {
      patient_id: { value: observation&.subject&.reference&.match(%r{^Patient/(\d+)$}).to_a[1], path: 'Observation.subject.reference' },
      lab_type: { value: lab_type, path: 'Observation.code.coding[0]', errors: lab_type_errors },
      specimen_collection: { value: observation&.effectiveDateTime, path: 'Observation.effectiveDateTime' },
      report: { value: observation&.issued&.split('T')&.first, path: 'Observation.issued' },
      result: { value: result, path: 'Observation.valueCodeableConcept.coding[0]', errors: result_errors }
    }
  end

  # Returns a representative FHIR::QuestionnaireResponse for an instance of a Sara Alert Assessment.
  # https://www.hl7.org/fhir/questionnaireresponse.html
  def assessment_as_fhir(assessment)
    FHIR::QuestionnaireResponse.new(
      meta: FHIR::Meta.new(lastUpdated: assessment.updated_at.strftime('%FT%T%:z')),
      id: assessment.id,
      subject: FHIR::Reference.new(reference: "Patient/#{assessment.patient_id}"),
      status: 'completed',
      extension: [
        to_bool_extension(assessment.symptomatic, 'symptomatic'),
        to_datetime_extension(assessment.created_at, 'created-at'),
        to_string_extension(assessment.who_reported, 'who-reported')
      ],
      item: assessment.reported_condition.symptoms.enum_for(:each_with_index).collect do |s, index|
        case s.type
        when 'IntegerSymptom'
          FHIR::QuestionnaireResponse::Item.new(
            text: s.name,
            answer: to_questionnaire_response_answer(:valueInteger, s.int_value),
            linkId: index.to_s
          )
        when 'FloatSymptom'
          FHIR::QuestionnaireResponse::Item.new(
            text: s.name,
            answer: to_questionnaire_response_answer(:valueDecimal, s.float_value),
            linkId: index.to_s
          )
        when 'BoolSymptom'
          FHIR::QuestionnaireResponse::Item.new(
            text: s.name,
            answer: to_questionnaire_response_answer(:valueBoolean, s.bool_value),
            linkId: index.to_s
          )
        end
      end
    )
  end

  def to_questionnaire_response_answer(field, value)
    if value.nil?
      FHIR::QuestionnaireResponse::Item::Answer.new(
        valueCoding: FHIR::Coding.new(
          system: 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor',
          code: 'UNK'
        )
      )
    else
      FHIR::QuestionnaireResponse::Item::Answer.new(field => value)
    end
  end

  def transfer_as_fhir_extension(transfer)
    FHIR::Extension.new(
      url: SA_EXT_BASE_URL + 'transfer',
      extension: [
        FHIR::Extension.new(url: 'id', valuePositiveInt: transfer.id),
        FHIR::Extension.new(url: 'updated-at', valueDateTime: transfer.updated_at.strftime('%FT%T%:z')),
        FHIR::Extension.new(url: 'created-at', valueDateTime: transfer.updated_at.strftime('%FT%T%:z')),
        FHIR::Extension.new(url: 'who-initiated-transfer', valueString: transfer.who.email),
        FHIR::Extension.new(url: 'from-jurisdiction', valueString: transfer.from_jurisdiction[:path]),
        FHIR::Extension.new(url: 'to-jurisdiction', valueString: transfer.to_jurisdiction[:path])
      ]
    )
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
    return nil if ethnicity.nil? || !ValidationHelper::VALID_PATIENT_ENUMS[:ethnicity].include?(ethnicity)

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
    mapped_lang = Languages.normalize_and_get_language_code(language)
    return nil if mapped_lang.nil? # Patients should not have invalid languages, but still safer to check here

    language = Languages.all_languages[mapped_lang.to_sym]
    fhir_coding = FHIR::Coding.new
    fhir_coding.code = language[:iso6391code] || mapped_lang
    fhir_coding.display = language[:display]
    fhir_coding.system = 'urn:ietf:bcp:47'
    fhir_coding
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

  # Convert from a boolean extension, treating omission (nil) as different than false
  def from_bool_extension_nil_default(element, base_path, extension_id)
    { value: element&.extension&.find { |e| e.url.include?(extension_id) }&.valueBoolean, path: bool_ext_path(base_path, extension_id) }
  end

  def to_date_extension(value, extension_id)
    value.blank? ? nil : FHIR::Extension.new(
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

  def to_datetime_extension(value, extension_id)
    value.blank? ? nil : FHIR::Extension.new(
      url: SA_EXT_BASE_URL + extension_id,
      valueDateTime: value.strftime('%FT%T%:z')
    )
  end

  def to_string_extension(value, extension_id)
    value.nil? || value.empty? ? nil : FHIR::Extension.new(
      url: SA_EXT_BASE_URL + extension_id,
      valueString: value
    )
  end

  def from_string_extension(element, base_path, extension_id, default_value = nil)
    { value: element&.extension&.find { |e| e.url.include?(extension_id) }&.valueString || default_value, path: str_ext_path(base_path, extension_id) }
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

  def from_interpreter_required_extension(element, base_path)
    {
      value: element&.extension&.find { |e| e.url.include?(INTERPRETER_URL) }&.valueBoolean,
      path: "#{base_path}.extension(#{INTERPRETER_URL}).valueBoolean"
    }
  end

  def to_interpreter_required_extension(value)
    value.nil? ? nil : FHIR::Extension.new(
      url: INTERPRETER_URL,
      valueBoolean: value
    )
  end

  def from_fhir_phone_number(value)
    Phonelib.parse(value, 'US').full_e164.presence || value
  end

  def to_statelocal_identifier(statelocal_identifier)
    FHIR::Identifier.new(value: statelocal_identifier, system: 'http://saraalert.org/SaraAlert/state-local-id') unless statelocal_identifier.blank?
  end

  def to_identifier(value, system_id)
    FHIR::Identifier.new(value: value, system: "http://saraalert.org/SaraAlert/#{system_id}") unless value.blank?
  end

  def from_identifier(identifier, system_id, base_path)
    id = identifier&.find { |i| i&.system == "http://saraalert.org/SaraAlert/#{system_id}" }
    { value: id&.value, path: "#{base_path}.identifier[#{identifier&.index(id)}].value" }
  end

  def to_communication(language, preferred)
    coded_language = language_coding(language)
    coded_language ? FHIR::Patient::Communication.new(
      language: FHIR::CodeableConcept.new(coding: [coded_language]),
      preferred: preferred
    ) : nil
  end

  def from_communication(communication, index)
    if communication&.dig(index)&.language&.coding&.first&.code.nil?
      lang = communication&.dig(index)&.language&.coding&.first&.display
      lang_path = "Patient.communication[#{index}].language.coding[0].display"
    else
      lang = communication&.dig(index)&.language&.coding&.first&.code
      lang_path = "Patient.communication[#{index}].language.coding[0].code"
    end
    { value: Languages.attempt_language_matching(lang), path: lang_path }
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
       patient.foreign_address_state].any?(&:present?) ?
      FHIR::Address.new(
        line: [patient.foreign_address_line_1, patient.foreign_address_line_2, patient.foreign_address_line_3].reject(&:blank?),
        city: patient.foreign_address_city,
        country: patient.foreign_address_country,
        state: patient.foreign_address_state,
        postalCode: patient.foreign_address_zip,
        extension: [FHIR::Extension.new(url: "#{SA_EXT_BASE_URL}address-type", valueString: 'Foreign')]
      ) : nil
    when 'Monitored'
      [patient.monitored_address_line_1,
       patient.monitored_address_line_2,
       patient.monitored_address_city,
       patient.monitored_address_county,
       patient.monitored_address_zip,
       patient.monitored_address_state].any?(&:present?) ?
       FHIR::Address.new(
         line: [patient.monitored_address_line_1, patient.monitored_address_line_2].reject(&:blank?),
         city: patient.monitored_address_city,
         district: patient.monitored_address_county,
         state: patient.monitored_address_state,
         postalCode: patient.monitored_address_zip,
         extension: [FHIR::Extension.new(url: "#{SA_EXT_BASE_URL}address-type", valueString: 'Monitored')]
       ) : nil
    when 'ForeignMonitored'
      [patient.foreign_monitored_address_line_1,
       patient.foreign_monitored_address_line_2,
       patient.foreign_monitored_address_city,
       patient.foreign_monitored_address_county,
       patient.foreign_monitored_address_zip,
       patient.foreign_monitored_address_state].any?(&:present?) ?
       FHIR::Address.new(
         line: [patient.foreign_monitored_address_line_1, patient.foreign_monitored_address_line_2].reject(&:blank?),
         city: patient.foreign_monitored_address_city,
         district: patient.foreign_monitored_address_county,
         state: patient.foreign_monitored_address_state,
         postalCode: patient.foreign_monitored_address_zip,
         extension: [FHIR::Extension.new(url: "#{SA_EXT_BASE_URL}address-type", valueString: 'ForeignMonitored')]
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

  # Return an extension that captures all of the exposure risk factors for a monitoree
  def to_exposure_risk_factors_extension(patient)
    subextensions = [
      to_risk_factor_subextension('contact-of-known-case', 'contact-of-known-case-id', patient.contact_of_known_case, patient.contact_of_known_case_id),
      to_risk_factor_subextension('was-in-health-care-facility-with-known-cases', 'was-in-health-care-facility-with-known-cases-facility-name',
                                  patient.was_in_health_care_facility_with_known_cases, patient.was_in_health_care_facility_with_known_cases_facility_name),
      to_risk_factor_subextension('laboratory-personnel', 'laboratory-personnel-facility-name', patient.laboratory_personnel,
                                  patient.laboratory_personnel_facility_name),
      to_risk_factor_subextension('healthcare-personnel', 'healthcare-personnel-facility-name', patient.healthcare_personnel,
                                  patient.healthcare_personnel_facility_name),
      to_risk_factor_subextension('member-of-a-common-exposure-cohort', 'member-of-a-common-exposure-cohort-type',
                                  patient.member_of_a_common_exposure_cohort, patient.member_of_a_common_exposure_cohort_type),
      to_bool_extension(patient.travel_to_affected_country_or_area || false, 'travel-from-affected-country-or-area'),
      to_bool_extension(patient.crew_on_passenger_or_cargo_flight || false, 'crew-on-passenger-or-cargo-flight')
    ]

    FHIR::Extension.new(
      url: "#{SA_EXT_BASE_URL}exposure-risk-factors",
      extension: subextensions
    )
  end

  # Return a sub-extension which represents a certain risk factor bool/string pair
  def to_risk_factor_subextension(risk_factor_id, string_id, bool_value, string_value)
    FHIR::Extension.new(
      url: "#{SA_EXT_BASE_URL}#{risk_factor_id}",
      extension: [
        FHIR::Extension.new(
          url: risk_factor_id,
          valueBoolean: bool_value || false
        ),
        string_value.blank? ? nil : FHIR::Extension.new(
          url: string_id,
          valueString: string_value
        )
      ]
    )
  end

  # Map an exposure-risk-factors extension to a hash of fields on a Patient.
  # Hash is of the form:
  # {
  #  attribute_name: { value: <converted-value>, path: <fhirpath-to-corresponding-fhir-element> }
  # }
  def from_exposure_risk_factors_extension(patient)
    ext = patient&.extension&.find { |e| e.url == "#{SA_EXT_BASE_URL}exposure-risk-factors" }
    return {} if ext.nil?

    ext_idx = patient.extension.index(ext)
    risk_factors =
      {
        travel_to_affected_country_or_area: from_bool_extension_false_default(ext, "Patient.extension[#{ext_idx}]", 'travel-from-affected-country-or-area'),
        crew_on_passenger_or_cargo_flight: from_bool_extension_false_default(ext, "Patient.extension[#{ext_idx}]", 'crew-on-passenger-or-cargo-flight')
      }
    ext.extension&.each_with_index do |sub_ext, sub_ext_idx|
      case sub_ext.url
      when "#{SA_EXT_BASE_URL}contact-of-known-case"
        sub_ext_risk_factors =
          {
            contact_of_known_case: from_bool_extension_false_default(sub_ext, "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]",
                                                                     'contact-of-known-case'),
            contact_of_known_case_id: from_string_extension(sub_ext, "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]", 'contact-of-known-case-id')
          }
      when "#{SA_EXT_BASE_URL}was-in-health-care-facility-with-known-cases"
        sub_ext_risk_factors =
          {
            was_in_health_care_facility_with_known_cases: from_bool_extension_false_default(sub_ext, "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]",
                                                                                            'was-in-health-care-facility-with-known-cases'),
            was_in_health_care_facility_with_known_cases_facility_name: from_string_extension(sub_ext,
                                                                                              "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]",
                                                                                              'was-in-health-care-facility-with-known-cases-facility-name')
          }
      when "#{SA_EXT_BASE_URL}laboratory-personnel"
        sub_ext_risk_factors =
          {
            laboratory_personnel: from_bool_extension_false_default(sub_ext, "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]", 'laboratory-personnel'),
            laboratory_personnel_facility_name: from_string_extension(sub_ext, "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]",
                                                                      'laboratory-personnel-facility-name')
          }
      when "#{SA_EXT_BASE_URL}healthcare-personnel"
        sub_ext_risk_factors =
          {
            healthcare_personnel: from_bool_extension_false_default(sub_ext, "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]", 'healthcare-personnel'),
            healthcare_personnel_facility_name: from_string_extension(sub_ext, "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]",
                                                                      'healthcare-personnel-facility-name')
          }
      when "#{SA_EXT_BASE_URL}member-of-a-common-exposure-cohort"
        sub_ext_risk_factors =
          {
            member_of_a_common_exposure_cohort: from_bool_extension_false_default(sub_ext, "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]",
                                                                                  'member-of-a-common-exposure-cohort'),
            member_of_a_common_exposure_cohort_type: from_string_extension(sub_ext, "Patient.extension[#{ext_idx}].extension[#{sub_ext_idx}]",
                                                                           'member-of-a-common-exposure-cohort-type')
          }
      else
        next
      end
      risk_factors.merge!(sub_ext_risk_factors.transform_values { |v| { value: v[:value], path: v[:path].sub(SA_EXT_BASE_URL, '') } })
    end
    risk_factors
  end

  # Return an extension which represents the source of report for a monitoree
  def to_report_source_extension(patient)
    return nil if patient.source_of_report.blank?

    FHIR::Extension.new(
      url: SA_EXT_BASE_URL + 'source-of-report',
      extension: [
        FHIR::Extension.new(
          url: 'source-of-report',
          valueString: patient.source_of_report
        ),
        patient.source_of_report_specify.blank? ? nil : FHIR::Extension.new(
          url: 'specify',
          valueString: patient.source_of_report_specify
        )
      ]
    )
  end

  # Map a source-of-report extension to a hash of fields on a Patient.
  # Hash is of the form:
  # {
  #  attribute_name: { value: <converted-value>, path: <fhirpath-to-corresponding-fhir-element> }
  # }
  def from_report_source_extension(patient)
    ext = patient&.extension&.find { |e| e.url == "#{SA_EXT_BASE_URL}source-of-report" }
    return {} if ext.nil?

    ext_idx = patient.extension.index(ext)
    {
      source_of_report: from_string_extension(ext, "Patient.extension[#{ext_idx}]", 'source-of-report'),
      source_of_report_specify: from_string_extension(ext, "Patient.extension[#{ext_idx}]", 'specify')
    }.compact.transform_values { |v| { value: v[:value], path: v[:path].sub(SA_EXT_BASE_URL, '') } }
  end

  def to_gender_identity_extension(gender_identity)
    fhir_gender_identity = GENDER_IDENTITY_TO_FHIR[gender_identity]

    return nil if fhir_gender_identity.blank?

    FHIR::Extension.new(
      url: 'http://hl7.org/fhir/StructureDefinition/patient-genderIdentity',
      valueCodeableConcept: FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: fhir_gender_identity['system'],
            code: fhir_gender_identity['code']
          )
        ],
        text: gender_identity
      )
    )
  end

  def from_gender_identity_extension(patient, base_path)
    ext_url = 'http://hl7.org/fhir/StructureDefinition/patient-genderIdentity'
    ext = patient&.extension&.find { |e| e.url == ext_url }

    gender_identity = GENDER_IDENTITY_FROM_FHIR[
      {
        'system' => ext&.valueCodeableConcept&.coding&.first&.system,
        'code' => ext&.valueCodeableConcept&.coding&.first&.code
      }
    ]
    if !ext.nil? && gender_identity.nil?
      {
        errors:
          [
            'is not an acceptable value, acceptable values are: '\
            "#{GENDER_IDENTITY_FROM_FHIR.keys.map do |c|
                 pretty_print_code_from_fhir(c)
               end.join(', ')}"
          ],
        path: "#{base_path}.extension('#{ext_url}').valueCodeableConcept"
      }
    else
      {
        value: gender_identity,
        path: "#{base_path}.extension('#{ext_url}').valueCodeableConcept"
      }
    end
  end

  def to_sexual_orientation_extension(sexual_orientation)
    fhir_sexual_orientation = SEXUAL_ORIENTATION_TO_FHIR[sexual_orientation]

    return nil if fhir_sexual_orientation.blank?

    FHIR::Extension.new(
      url: 'http://saraalert.org/StructureDefinition/sexual-orientation',
      valueCodeableConcept: FHIR::CodeableConcept.new(
        coding: [
          FHIR::Coding.new(
            system: fhir_sexual_orientation['system'],
            code: fhir_sexual_orientation['code']
          )
        ],
        text: sexual_orientation
      )
    )
  end

  def from_sexual_orientation_extension(patient, base_path)
    ext_url = 'http://saraalert.org/StructureDefinition/sexual-orientation'
    ext = patient&.extension&.find { |e| e.url == ext_url }

    sexual_orientation = SEXUAL_ORIENTATION_FROM_FHIR[
      {
        'system' => ext&.valueCodeableConcept&.coding&.first&.system,
        'code' => ext&.valueCodeableConcept&.coding&.first&.code
      }
    ]
    if !ext.nil? && sexual_orientation.nil?
      {
        errors:
          [
            'is not an acceptable value, acceptable values are: '\
            "#{SEXUAL_ORIENTATION_FROM_FHIR.keys.map do |c|
                 pretty_print_code_from_fhir(c)
               end.join(', ')}"
          ],
        path: "#{base_path}.extension('#{ext_url}').valueCodeableConcept"
      }
    else
      {
        value: sexual_orientation,
        path: "#{base_path}.extension('#{ext_url}').valueCodeableConcept"
      }
    end
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

  def pretty_print_code_from_fhir(code_hash)
    return nil unless code_hash['system'] && code_hash['code']

    "#{code_hash['system']}##{code_hash['code']}"
  end

  def patients_to_fhir_bundle(patients)
    results = []
    patients.each do |patient|
      patient_as_fhir = patient.as_fhir
      results << FHIR::Bundle::Entry.new(fullUrl: full_url_helper(patient_as_fhir), resource: patient_as_fhir,
                                         response: FHIR::Bundle::Entry::Response.new(status: '201 Created'))
      patient.laboratories.each do |lab|
        lab_as_fhir = lab.as_fhir
        results << FHIR::Bundle::Entry.new(fullUrl: full_url_helper(lab_as_fhir), resource: lab_as_fhir,
                                           response: FHIR::Bundle::Entry::Response.new(status: '201 Created'))
      end
    end

    FHIR::Bundle.new(
      id: SecureRandom.uuid,
      meta: FHIR::Meta.new(lastUpdated: DateTime.now.strftime('%FT%T%:z')),
      type: 'transaction-response',
      entry: results
    )
  end

  def validate_transaction_bundle(bundle)
    # Only accept transaction Bundles
    if bundle.resourceType&.downcase != 'bundle' || bundle.type&.downcase != 'transaction'
      return ["Only Bundles of type 'transaction' are allowed", 'Bundle.type']
    end

    # Validate the entries
    bundle.entry&.each_with_index do |entry, index|
      resource_type = entry.resource&.resourceType&.downcase

      # Check for valid resourceType
      unless %w[observation patient].include?(resource_type)
        return ["All entries must contain a resource of type 'Observation' or 'Patient'", "Bundle.entry[#{index}].resource"]
      end

      # Check for valid Bundle.entry.request
      unless entry.request&.local_method == 'POST' && entry.request&.url&.downcase == resource_type
        return [
          "Invalid request method, request.method must be 'POST' and request.url must be 'Patient' or 'Observation",
          "Bundle.entry[#{index}].request"
        ]
      end
    end
    []
  end
end
