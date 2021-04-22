# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# ApiController: API for interacting with Sara Alert
class Fhir::R4::ApiController < ActionController::API
  include ValidationHelper
  include FhirHelper
  include ActionController::MimeResponds
  before_action :cors_headers
  before_action only: %i[create update] do
    doorkeeper_authorize!(
      :'user/Patient.write',
      :'user/Patient.*',
      :'system/Patient.write',
      :'system/Patient.*',
      :'user/RelatedPerson.write',
      :'user/RelatedPerson.*',
      :'system/RelatedPerson.write',
      :'system/RelatedPerson.*'
    )
  end
  before_action only: %i[show search] do
    doorkeeper_authorize!(
      :'user/Patient.read',
      :'user/Patient.*',
      :'user/RelatedPerson.read',
      :'user/RelatedPerson.*',
      :'user/Immunization.read',
      :'user/Immunization.*',
      :'user/Observation.read',
      :'user/QuestionnaireResponse.read',
      :'system/Patient.read',
      :'system/Patient.*',
      :'system/RelatedPerson.read',
      :'system/RelatedPerson.*',
      :'system/Immunization.read',
      :'system/Immunization.*',
      :'system/Observation.read',
      :'system/QuestionnaireResponse.read'
    )
  end
  before_action :check_client_type
  rescue_from StandardError, with: :handle_server_error

  # Return a resource given a type and an id.
  #
  # Supports (reading): Patient, Observation, QuestionnaireResponse, RelatedPerson, Immunization
  #
  # GET /[:resource_type]/[:id]
  def show
    status_not_acceptable && return unless accept_header?

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      return if doorkeeper_authorize!(
        :'user/Patient.read',
        :'user/Patient.*',
        :'system/Patient.read',
        :'system/Patient.*'
      )

      resource = get_patient(params.permit(:id)[:id])
    when 'observation'
      return if doorkeeper_authorize!(
        :'user/Observation.read',
        :'system/Observation.read'
      )

      resource = get_laboratory(params.permit(:id)[:id])
    when 'questionnaireresponse'
      return if doorkeeper_authorize!(
        :'user/QuestionnaireResponse.read',
        :'system/QuestionnaireResponse.read'
      )

      resource = get_assessment(params.permit(:id)[:id])
    when 'relatedperson'
      return if doorkeeper_authorize!(
        :'user/RelatedPerson.read',
        :'user/RelatedPerson.*',
        :'system/RelatedPerson.read',
        :'system/RelatedPerson.*'
      )

      resource = get_close_contact(params.permit(:id)[:id])
    when 'immunization'
      return if doorkeeper_authorize!(
        :'user/Immunization.read',
        :'user/Immunization.*',
        :'system/Immunization.read',
        :'system/Immunization.*'
      )

      resource = get_vaccine(params.permit(:id)[:id])
    else
      status_not_found && return
    end

    status_forbidden && return if resource.nil?

    status_ok(resource.as_fhir) && return
  end

  # Update a resource given a type and an id.
  #
  # Supports (updating): Patient, RelatedPerson, Immunization
  #
  # PUT /fhir/r4/[:resource_type]/[:id]
  def update
    if request.patch?
      status_unsupported_media_type && return unless content_type_header?('application/json-patch+json')

      # Parse in the JSON patch
      patch = Hana::Patch.new(JSON.parse(request.body.string))
    else
      status_unsupported_media_type && return unless content_type_header?('application/fhir+json')

      # Parse in the FHIR
      contents = FHIR.from_contents(request.body.string)
      errors = contents&.validate
      status_bad_request(format_fhir_validation_errors(errors)) && return if contents.nil? || !errors.empty?
    end

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      return if doorkeeper_authorize!(
        :'user/Patient.write',
        :'user/Patient.*',
        :'system/Patient.write',
        :'system/Patient.*'
      )

      # Get the patient that needs to be updated
      patient = get_patient(params.permit(:id)[:id])
      status_forbidden && return if patient.nil?

      # Get the contents from applying a patch, if needed
      if request.patch? && !patient.nil?
        begin
          contents = apply_patch(patient, patch)
        rescue StandardError => e
          status_bad_request([['Unable to apply patch', e&.message].compact.join(': ')]) && return
        end
      end

      # Get patient values before updates occur for later comparison
      patient_before = patient.dup

      # Get key value pairs from the update.
      # fhir_map is of the form:
      # { attribute_name: { value: <converted-value>, path: <fhirpath-to-corresponding-fhir-element> } }
      fhir_map = patient_from_fhir(contents, default_patient_jurisdiction_id)
      request_updates = fhir_map.transform_values { |v| v[:value] }
      status_unprocessable_entity(nil, nil, nil) && return if request_updates.nil?

      # Assign any remaining updates to the patient
      # NOTE: The patient.update method does not allow a context to be passed, so first we assign the updates, then save
      patient.assign_attributes(request_updates)

      # Wrap updates to the Patient, Transfer creation, and History creation in a transaction
      # so that they occur atomically
      ActiveRecord::Base.transaction do
        # Verify that the updated jurisdiction and other updates are valid
        unless jurisdiction_valid_for_update?(patient) && patient.save(context: :api)
          req_json = request.patch? ? patient.as_fhir.to_json : JSON.parse(request.body.string)
          status_unprocessable_entity(patient, fhir_map, req_json) && return
        end

        # If the jurisdiction was changed, create a Transfer
        if request_updates&.keys&.include?(:jurisdiction_id) && !request_updates[:jurisdiction_id].nil?
          Transfer.create!(patient: patient, from_jurisdiction: patient_before.jurisdiction, to_jurisdiction: patient.jurisdiction, who: @current_actor)
        end

        # Handle creating history items based on all of the updates
        update_all_patient_history(request_updates, patient_before, patient)
      end

      status_ok(patient.as_fhir) && return
    when 'relatedperson'
      return if doorkeeper_authorize!(
        :'user/RelatedPerson.write',
        :'user/RelatedPerson.*',
        :'system/RelatedPerson.write',
        :'system/RelatedPerson.*'
      )

      # Get the CloseContact that needs to be updated
      close_contact = get_close_contact(params.permit(:id)[:id])
      status_forbidden && return if close_contact.nil?

      # Get the contents from applying a patch, if needed
      if request.patch? && !close_contact.nil?
        begin
          contents = apply_patch(close_contact, patch)
        rescue StandardError => e
          status_bad_request([['Unable to apply patch', e&.message].compact.join(': ')]) && return
        end
      end

      fhir_map = close_contact_from_fhir(contents)
      request_updates = fhir_map.transform_values { |v| v[:value] }
      status_unprocessable_entity && return if request_updates.nil?

      # Assign any remaining updates to the close_contact
      close_contact.assign_attributes(request_updates)

      # Wrap updates to the CloseContact and History creation in a transaction
      ActiveRecord::Base.transaction do
        unless referenced_patient_valid_for_client?(close_contact, :patient_id) && close_contact.save(context: :api)
          req_json = request.patch? ? close_contact.as_fhir.to_json : JSON.parse(request.body.string)
          status_unprocessable_entity(close_contact, fhir_map, req_json) && return
        end

        Rails.logger.info "Updated Close Contact (ID: #{close_contact.id}) for Patient with ID: #{close_contact.patient_id}"
        History.close_contact_edit(patient: close_contact.patient_id,
                                   created_by: @current_actor_label,
                                   comment: "Close contact edited via the API (ID: #{close_contact.id}).")
      end
      status_ok(close_contact.as_fhir) && return
    when 'immunization'
      return if doorkeeper_authorize!(
        :'user/Immunization.write',
        :'user/Immunization.*',
        :'system/Immunization.write',
        :'system/Immunization.*'
      )

      # Get the Vaccine that needs to be updated
      vaccine = get_vaccine(params.permit(:id)[:id])
      status_forbidden && return if vaccine.nil?

      # Get the contents from applying a patch, if needed
      if request.patch? && !vaccine.nil?
        begin
          contents = apply_patch(vaccine, patch)
        rescue StandardError => e
          status_bad_request([['Unable to apply patch', e&.message].compact.join(': ')]) && return
        end
      end

      fhir_map = vaccine_from_fhir(contents)
      request_updates = fhir_map.transform_values { |v| v[:value] }
      status_unprocessable_entity && return if request_updates.nil?

      # Assign any remaining updates to the vaccine
      vaccine.assign_attributes(request_updates)

      # Wrap updates to the Vaccine and History creation in a transaction
      ActiveRecord::Base.transaction do
        unless referenced_patient_valid_for_client?(vaccine, :patient_id) && vaccine.save
          req_json = request.patch? ? vaccine.as_fhir.to_json : JSON.parse(request.body.string)
          status_unprocessable_entity(vaccine, fhir_map, req_json) && return
        end

        Rails.logger.info "Updated Vaccination (ID: #{vaccine.id}) for Patient with ID: #{vaccine.patient_id}"
        History.vaccination_edit(patient: vaccine.patient_id,
                                 created_by: @current_actor_label,
                                 comment: "Vaccination edited via the API (ID: #{vaccine.id}).")
      end
      status_ok(vaccine.as_fhir) && return
    else
      status_not_found && return
    end
  rescue JSON::ParserError
    status_bad_request(['Invalid JSON in request body'])
  end

  # Create History items corresponding to Patient changes from an update.
  #
  # updates - A hash that contains attributes corresponding to the Patient.
  # patient_before - The Patient before updates were applied.
  # patient - The Patient after the updates have been applied.
  def update_all_patient_history(updates, patient_before, patient)
    # Handle History for monitoree details information updates
    # NOTE: "isolation" is a special case, because it is not a monitoring field, but it has side effects that are handled
    # alongside monitoring fields
    info_updates = updates.filter { |attr, _value| !PatientHelper.monitoring_fields.include?(attr) || attr == :isolation }
    Patient.detailed_history_edit(patient_before, patient, info_updates&.keys, @current_actor_label)

    # Handle History for monitoree monitoring information updates
    history_data = {
      created_by: @current_actor_label,
      patient_before: patient_before,
      patient: patient,
      updates: updates,
      household_status: :patient,
      propagation: :none
    }
    patient.monitoring_history_edit(history_data, nil)
  end

  # Create a resource given a type.
  #
  # Supports (writing): Patient, RelatedPerson, Immunization
  #
  # POST /fhir/r4/[:resource_type]
  def create
    status_unsupported_media_type && return unless content_type_header?('application/fhir+json')

    # Parse in the FHIR
    contents = FHIR.from_contents(request.body.string)
    errors = contents&.validate
    status_bad_request(format_fhir_validation_errors(errors)) && return if contents.nil? || !errors.empty?

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      return if doorkeeper_authorize!(
        :'user/Patient.write',
        :'user/Patient.*',
        :'system/Patient.write',
        :'system/Patient.*'
      )

      # Construct a Sara Alert Patient
      # fhir_map is of the form:
      # { attribute_name: { value: <converted-value>, path: <fhirpath-to-corresponding-fhir-element> } }
      fhir_map = patient_from_fhir(contents, default_patient_jurisdiction_id)
      vals = fhir_map.transform_values { |v| v[:value] }
      resource = Patient.new(vals)

      # Responder is self
      resource.responder = resource

      # Storing call method call in variable for efficiency
      patients = accessible_patients

      # Set the responder for this patient, this will link patients that have duplicate primary contact info
      if ['SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].include? resource[:preferred_contact_method]
        if patients.responder_for_number(resource[:primary_telephone])&.exists?
          resource.responder = patients.responder_for_number(resource[:primary_telephone]).first
        end
      elsif resource[:preferred_contact_method] == 'E-mailed Web Link'
        resource.responder = patients.responder_for_email(resource[:email]).first if patients.responder_for_email(resource[:email])&.exists?
      end

      # Default responder to self if no responder condition met
      resource.responder = resource if resource.responder.nil?

      # Determine resource creator
      resource.creator = @current_actor

      # Generate submission token for monitoree
      resource.submission_token = resource.new_submission_token

      status_bad_request && return if resource.nil?

      ActiveRecord::Base.transaction do
        unless jurisdiction_valid_for_client?(resource) && resource.save(context: :api)
          req_json = JSON.parse(request.body.string)
          status_unprocessable_entity(resource, fhir_map, req_json) && return
        end

        # Create a history for the enrollment
        History.enrollment(patient: resource, created_by: @current_actor_label, comment: 'Monitoree enrolled via API.')
      end

      # This is necessary since the transaction will swallow an ActiveRecord::Rollback error
      raise(StandardError, 'Error when saving Patient to the database') if resource.id.nil?

      Rails.logger.info "Created Patient with ID: #{resource.id}"
      # Send enrollment notification only to responders
      resource.send_enrollment_notification if resource.self_reporter_or_proxy?
    when 'relatedperson'
      return if doorkeeper_authorize!(
        :'user/RelatedPerson.write',
        :'user/RelatedPerson.*',
        :'system/RelatedPerson.write',
        :'system/RelatedPerson.*'
      )

      fhir_map = close_contact_from_fhir(contents)
      vals = fhir_map.transform_values { |v| v[:value] }
      resource = CloseContact.new(vals)

      ActiveRecord::Base.transaction do
        unless referenced_patient_valid_for_client?(resource, :patient_id) && resource.save(context: :api)
          req_json = JSON.parse(request.body.string)
          status_unprocessable_entity(resource, fhir_map, req_json) && return
        end

        Rails.logger.info "Created Close Contact (ID: #{resource.id}) for Patient with ID: #{resource.patient_id}"
        History.close_contact(patient: resource.patient_id,
                              created_by: @current_actor_label,
                              comment: "New close contact added via API (ID: #{resource.id}).")
      end
    when 'immunization'
      return if doorkeeper_authorize!(
        :'user/Immunization.write',
        :'user/Immunization.*',
        :'system/Immunization.write',
        :'system/Immunization.*'
      )

      fhir_map = vaccine_from_fhir(contents)
      vals = fhir_map.transform_values { |v| v[:value] }
      resource = Vaccine.new(vals)

      ActiveRecord::Base.transaction do
        unless referenced_patient_valid_for_client?(resource, :patient_id) && resource.save
          req_json = JSON.parse(request.body.string)
          status_unprocessable_entity(resource, fhir_map, req_json) && return
        end

        Rails.logger.info "Created Vaccine (ID: #{resource.id}) for Patient with ID: #{resource.patient_id}"
        History.vaccination(patient: resource.patient_id,
                            created_by: @current_actor_label,
                            comment: "New vaccine added via API (ID: #{resource.id}).")
      end
    else
      status_not_found && return
    end
    status_created(resource.as_fhir) && return
  rescue JSON::ParserError
    status_bad_request(['Invalid JSON in request body'])
  end

  # Return a FHIR Bundle containing results that match the given query.
  #
  # Supports (searching): Patient, Observation, QuestionnaireResponse, RelatedPerson, Immunization
  #
  # GET /fhir/r4/[:resource_type]?parameter(s)
  def search
    status_not_acceptable && return unless accept_header?

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    search_params = params.slice('family', 'given', 'telecom', 'email', 'subject', 'active',
                                 '_count', '_id', 'patient')
    case resource_type
    when 'patient'
      return if doorkeeper_authorize!(
        :'user/Patient.read',
        :'user/Patient.*',
        :'system/Patient.read',
        :'system/Patient.*'
      )

      resources = search_patients(search_params)
      resource_type = 'Patient'
    when 'observation'
      return if doorkeeper_authorize!(
        :'user/Observation.read',
        :'system/Observation.read'
      )

      resources = search_laboratories(search_params) || []
      resource_type = 'Observation'
    when 'questionnaireresponse'
      return if doorkeeper_authorize!(
        :'user/QuestionnaireResponse.read',
        :'system/QuestionnaireResponse.read'
      )

      resources = search_assessments(search_params) || []
      resource_type = 'QuestionnaireResponse'
    when 'relatedperson'
      return if doorkeeper_authorize!(
        :'user/RelatedPerson.read',
        :'user/RelatedPerson.*',
        :'system/RelatedPerson.read',
        :'system/RelatedPerson.*'
      )

      resources = search_close_contacts(search_params) || []
      resource_type = 'RelatedPerson'
    when 'immunization'
      return if doorkeeper_authorize!(
        :'user/Immunization.read',
        :'user/Immunization.*',
        :'system/Immunization.read',
        :'system/Immunization.*'
      )

      resources = search_vaccines(search_params) || []
      resource_type = 'Immunization'
    else
      status_not_found && return
    end

    page_size = params.permit(:_count)[:_count].nil? ? 10 : params.permit(:_count)[:_count].to_i
    page_size = 500 if page_size > 500
    summary_mode = page_size.zero?
    page = params.permit(:page)[:page].to_i
    page = 1 if page.zero?
    results = []
    unless summary_mode || resources.blank?
      results = resources.paginate(per_page: page_size, page: page).collect do |r|
        FHIR::Bundle::Entry.new(fullUrl: full_url_helper(r.as_fhir), resource: r.as_fhir)
      end
    end

    # Construct bundle from search query
    bundle = FHIR::Bundle.new(
      id: SecureRandom.uuid,
      meta: FHIR::Meta.new(lastUpdated: DateTime.now.strftime('%FT%T%:z')),
      type: 'searchset',
      total: resources&.size || 0,
      link: summary_mode ? nil : bundle_search_links(page, page_size, resources, resource_type, search_params),
      entry: results
    )

    status_ok(bundle) && return
  end

  # Return a FHIR Bundle containing a monitoree and all their assessments, lab results,
  # and close contacts
  #
  # GET /fhir/r4/Patient/[:id]/$everything
  def all
    # Require all scopes for all four resources
    return if doorkeeper_authorize!(
      :'user/Patient.read',
      :'user/Patient.*',
      :'system/Patient.read',
      :'system/Patient.*'
    )
    return if doorkeeper_authorize!(
      :'user/Observation.read',
      :'system/Observation.read'
    )
    return if doorkeeper_authorize!(
      :'user/QuestionnaireResponse.read',
      :'system/QuestionnaireResponse.read'
    )
    return if doorkeeper_authorize!(
      :'user/RelatedPerson.read',
      :'user/RelatedPerson.*',
      :'system/RelatedPerson.read',
      :'system/RelatedPerson.*'
    )
    return if doorkeeper_authorize!(
      :'user/Immunization.read',
      :'user/Immunization.*',
      :'system/Immunization.read',
      :'system/Immunization.*'
    )

    status_not_acceptable && return unless accept_header?

    patient = get_patient(params.permit(:id)[:id])

    status_forbidden && return if patient.nil?

    # Gather assessments and lab results
    assessments = patient.assessments || []
    laboratories = patient.laboratories || []
    close_contacts = patient.close_contacts || []
    vaccines = patient.vaccines || []
    all = [patient] + assessments.to_a + laboratories.to_a + close_contacts.to_a + vaccines.to_a
    results = all.collect { |r| FHIR::Bundle::Entry.new(fullUrl: full_url_helper(r.as_fhir), resource: r.as_fhir) }

    # Construct bundle from monitoree and data
    bundle = FHIR::Bundle.new(
      id: SecureRandom.uuid,
      meta: FHIR::Meta.new(lastUpdated: DateTime.now.strftime('%FT%T%:z')),
      type: 'searchset',
      total: all.size,
      entry: results
    )

    status_ok(bundle) && return
  end

  # Return a FHIR::CapabilityStatement
  #
  # GET /fhir/r4/metadata
  def capability_statement
    resource = FHIR::CapabilityStatement.new(
      status: 'active',
      kind: 'instance',
      date: DateTime.parse('2021-03-04').strftime('%FT%T%:z'),
      software: FHIR::CapabilityStatement::Software.new(
        name: 'Sara Alert',
        version: ADMIN_OPTIONS['version']
      ),
      implementation: FHIR::CapabilityStatement::Implementation.new(
        description: 'Sara Alert API'
      ),
      fhirVersion: '4.0.1',
      format: %w[json],
      rest: FHIR::CapabilityStatement::Rest.new(
        mode: 'server',
        security: FHIR::CapabilityStatement::Rest::Security.new(
          cors: true,
          service: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(code: 'SMART-on-FHIR', system: 'http://hl7.org/fhir/restful-security-service')
            ],
            text: 'OAuth2 using SMART-on-FHIR profile (see http://docs.smarthealthit.org)'
          ),
          extension: [
            FHIR::Extension.new(
              url: 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris',
              extension: [
                FHIR::Extension.new(url: 'token', valueUri: "#{root_url}oauth/token"),
                FHIR::Extension.new(url: 'authorize', valueUri: "#{root_url}oauth/authorize"),
                FHIR::Extension.new(url: 'introspect', valueUri: "#{root_url}oauth/introspect"),
                FHIR::Extension.new(url: 'revoke', valueUri: "#{root_url}oauth/revoke")
              ]
            )
          ]
        ),
        resource: [
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'Patient',
            interaction: [
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'read'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'update'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'patch'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'create'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'search-type')
            ],
            searchParam: [
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'family', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'given', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'telecom', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'email', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'active', type: 'boolean'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: '_id', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: '_count', type: 'string')
            ]
          ),
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'RelatedPerson',
            interaction: [
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'read'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'update'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'patch'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'create'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'search-type')
            ],
            searchParam: [
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'patient', type: 'reference'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: '_id', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: '_count', type: 'string')
            ]
          ),
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'Observation',
            interaction: [
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'read'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'search-type')
            ],
            searchParam: [
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'subject', type: 'reference'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: '_id', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: '_count', type: 'string')
            ]
          ),
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'QuestionnaireResponse',
            interaction: [
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'read'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'search-type')
            ],
            searchParam: [
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'subject', type: 'reference'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: '_id', type: 'string'),
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: '_count', type: 'string')
            ]
          )
        ]
      )
    )
    status_ok(resource) && return
  end

  # Return a well known statement
  #
  # GET /fhir/r4/.well-known/smart-configuration
  def well_known
    render json: {
      authorization_endpoint: "#{root_url}oauth/authorize",
      token_endpoint: "#{root_url}oauth/token",
      token_endpoint_auth_methods_supported: %w[client_secret_basic private_key_jwt],
      token_endpoint_auth_signing_alg_values_supported: ['RS384'],
      introspection_endpoint: "#{root_url}oauth/introspect",
      revocation_endpoint: "#{root_url}oauth/revoke",
      scopes_supported: [
        'user/Patient.read',
        'user/Patient.write',
        'user/Patient.*',
        'user/Observation.read',
        'user/QuestionnaireResponse.read',
        'user/RelatedPerson.read',
        'user/RelatedPerson.write',
        'user/RelatedPerson.*',
        'system/Patient.read',
        'system/Patient.write',
        'system/Patient.*',
        'system/Observation.read',
        'system/QuestionnaireResponse.read',
        'system/RelatedPerson.read',
        'system/RelatedPerson.write',
        'system/RelatedPerson.*'
      ],
      capabilities: ['launch-standalone']
    }
  end

  # Handle OPTIONS requests for CORS preflight
  def options
    render plain: ''
  end

  private

  # Handle general unkown error. Log and serve a 500
  def handle_server_error(error)
    Rails.logger.error ([error.message] + error.backtrace).join("\n")
    render json: operation_outcome_fatal.to_json, status: :internal_server_error
  end

  # Check whether client is user or M2M flow, set instance variables appropriately.
  # Also return a 401 if user doesn't have API access
  def check_client_type
    return if doorkeeper_token.nil?

    if current_resource_owner.present?
      Rails.logger.info "Client: User, ID: #{current_resource_owner.id}, Email: #{current_resource_owner.email}"
      if current_resource_owner.can_use_api?
        @user_workflow = true
        @current_actor = current_resource_owner
        @current_actor_label = "#{current_resource_owner.email} (API)"
        nil
      else
        head :unauthorized
      end
    elsif current_client_application.present?
      Rails.logger.info "Client: Application, ID: #{current_client_application.id}, Name: #{current_client_application.name}"
      @m2m_workflow = true

      # Actor is client application - need to get created proxy user
      proxy_user = User.where(is_api_proxy: true).find_by(id: current_client_application.user_id)
      head :unauthorized if proxy_user.nil?
      @current_actor = proxy_user
      @current_actor_label = "#{current_client_application.name} (API)"
    end
  end

  # Current user account as authenticated via doorkeeper for user flow
  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token&.resource_owner_id
  end

  # Client application that is currently using the API
  def current_client_application
    OauthApplication.find_by(id: doorkeeper_token.application_id) if doorkeeper_token.application_id.present?
  end

  # Determine if the patient's jurisdiction is valid for the requesting application
  def jurisdiction_valid_for_client?(patient)
    if @user_workflow
      allowed_jurisdiction_ids = current_resource_owner&.jurisdiction&.subtree&.pluck(:id)
      if allowed_jurisdiction_ids.nil?
        patient.errors.add(:jurisdiction_id, 'User does not have a jurisdiction')
      elsif allowed_jurisdiction_ids.include?(patient.jurisdiction_id)
        return true
      else
        patient.errors.add(:jurisdiction_id, "Jurisdiction must be within the API user's jurisdiction hierarchy")
      end
    elsif @m2m_workflow
      allowed_jurisdiction_ids = current_client_application&.jurisdiction&.subtree&.pluck(:id)
      if allowed_jurisdiction_ids.nil?
        patient.errors.add(:jurisdiction_id, 'Client application does not have a jurisdiction')
      elsif allowed_jurisdiction_ids.include?(patient.jurisdiction_id)
        return true
      else
        patient.errors.add(:jurisdiction_id, "Jurisdiction must be within the client application's jurisdiction hierarchy")
      end
    end

    false
  end

  # Determine if the referenced patient is valid (accessible) for the client application
  def referenced_patient_valid_for_client?(resource, id_field)
    referenced_patient = accessible_patients.find_by_id(resource[id_field])

    return true unless referenced_patient.nil?

    if @user_workflow
      resource.errors.add(id_field, 'does not refer to a Patient which is accessible to the API user')
    elsif @m2m_workflow
      resource.errors.add(id_field, 'does not refer to a Patient which is accessible to the client application')
    end

    false
  end

  # Determine if a Patient's jurisdiction can be updated by the requesting application.
  #
  # patient - The Patient to check (patient.jurisdiction_id should be set to the updated value).
  #
  # Returns true if the jurisdiction is valid, otherwise false.
  def jurisdiction_valid_for_update?(patient)
    allowed_jurisdiction_ids = @current_actor.jurisdictions_for_transfer
    return true if !patient.jurisdiction_id.nil? && allowed_jurisdiction_ids.keys.include?(patient.jurisdiction_id)

    patient.errors.add(:jurisdiction_id, 'Jurisdiction does not exist or cannot be transferred to')

    false
  end

  # Default jurisdiction to assign to new monitorees
  def default_patient_jurisdiction_id
    if @user_workflow
      current_resource_owner&.jurisdiction&.id
    else
      current_client_application&.jurisdiction&.id
    end
  end

  # Determine the patient data that is accessible by either the current resource owner
  # (user flow) or the current client application (system flow).
  def accessible_patients
    # If there is a current resource owner (end user) that has api access enabled
    if @user_workflow
      # This will access all patients that the role has access to, if any
      current_resource_owner.patients
    # Otherwise if there NO resource owner and there is a found application, check for a valid associated jurisdiction id.
    # The current resource owner check is to prevent unauthorized users from using it if the application happens to be registered for both workflows.
    elsif @m2m_workflow
      jurisdiction_id = current_client_application[:jurisdiction_id]
      return unless Jurisdiction.exists?(jurisdiction_id)

      Jurisdiction.find_by(id: jurisdiction_id).all_patients_excluding_purged
    end
  end

  # Apply a patch to a resource that can be represented as FHIR
  def apply_patch(resource, patch)
    FHIR.from_contents(patch.apply(resource.as_fhir.to_hash).to_json)
  end

  # Check accept header for correct mime type (or allow fhir _format)
  def accept_header?
    return request.headers['Accept']&.include?('application/fhir+json') if params.permit(:_format)[:_format].nil?

    ['json', 'application/json', 'application/fhir+json'].include?(params.permit(:_format)[:_format]&.downcase)
  end

  # Check content type header for correct mime type
  def content_type_header?(header)
    request.content_type == header
  end

  # Generic 406 not acceptable
  def status_not_acceptable
    respond_to do |format|
      format.any { head :not_acceptable }
    end
  end

  # Generic 415 unsupported media type
  def status_unsupported_media_type
    respond_to do |format|
      format.any { head :unsupported_media_type }
    end
  end

  # Generic 400 bad request response
  def status_bad_request(errors = [])
    respond_to do |format|
      format.any { render json: errors.blank? ? operation_outcome_fatal.to_json : operation_outcome_with_errors(errors).to_json, status: :bad_request }
    end
  end

  # Generic 403 forbidden response
  def status_forbidden
    respond_to do |format|
      format.any { head :forbidden }
    end
  end

  # Generic 404 not found response
  def status_not_found
    respond_to do |format|
      format.any { head :not_found }
    end
  end

  # 422 response with specific validation errors.
  def status_unprocessable_entity(resource, fhir_map, req_json)
    outcome = FHIR::OperationOutcome.new(issue: [])

    # Add any errors that are tracked in the fhir_map
    fhir_map.each do |attribute, value|
      value[:errors]&.each do |error|
        # Only track the error in fhir_map, since additional errors would have been further down in processing
        resource.errors.delete(attribute)
        resource.errors.add(attribute, error)
      end
    end

    resource&.errors&.messages&.each do |attribute, errors|
      next unless VALIDATION.key?(attribute) || attribute == :base

      fhir_path = fhir_map&.dig(attribute, :path)

      # Extract the original value from the request body using FHIRPath
      if fhir_path&.present?
        begin
          value = nil
          # FHIRPath has a lot debug logging we don't care about, so suppress it.
          Rails.logger.silence do
            value = FHIRPath.evaluate(fhir_path, req_json)
          end
        rescue StandardError
          # If the FHIRPath evaluation fails for some reason, just use the normalized value that failed validation
          # Note that there is a known issue in the FHIRPath lib where nested calls to extension() result in an error
          # This issue is reported here: https://github.com/fhir-crucible/fhir_models/issues/82
          value = VALIDATION.dig(attribute, :checks)&.include?(:date) ? resource.public_send("#{attribute}_before_type_cast") : resource[attribute]
        end
      else
        value = VALIDATION.dig(attribute, :checks)&.include?(:date) ? resource.public_send("#{attribute}_before_type_cast") : resource[attribute]
      end

      msg_header = (value&.present? ? "Value '#{value}' for " : '') + "'#{VALIDATION.dig(attribute, :label)}'" unless attribute == :base
      errors.each do |error_message|
        # Exclude the actual value in logging to avoid PII/PHI
        Rails.logger.info "Validation Error on: #{attribute}"
        outcome.issue << FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'processing', diagnostics: "#{msg_header} #{error_message}".strip,
                                                           expression: fhir_path)
      end
    end

    respond_to do |format|
      format.any { render json: outcome.issue.blank? ? operation_outcome_fatal.to_json : outcome.to_json, status: :unprocessable_entity }
    end
  end

  # Generic 201 created response
  def status_created(resource)
    respond_to do |format|
      format.json { render json: resource.to_json, status: :created, location: full_url_helper(resource), content_type: 'application/fhir+json' }
      format.fhir_json { render json: resource.to_json, status: :ok, location: full_url_helper(resource), content_type: 'application/fhir+json' }
    end
  end

  # Generic 200 okay response
  def status_ok(resource)
    respond_to do |format|
      format.json { render json: resource.to_json, status: :ok, content_type: 'application/fhir+json' }
      format.fhir_json { render json: resource.to_json, status: :ok, content_type: 'application/fhir+json' }
    end
  end

  # Get a patient by id (if any patients, otherwise nil)
  def get_patient(id)
    accessible_patients&.find_by(id: id)
  end

  # Search for patients
  def search_patients(options)
    query = accessible_patients
    options.each do |option, search|
      next unless search.present?

      case option
      when 'family'
        query = query.where('last_name like ?', "%#{search}%")
      when 'given'
        query = query.where('first_name like ?', "%#{search}%")
      when 'telecom'
        query = query.where('primary_telephone like ?', Phonelib.parse(search, 'US').full_e164)
      when 'email'
        query = query.where('email like ?', "%#{search}%")
      when '_id'
        query = query.where(id: search)
      when 'active'
        query = query.where(monitoring: search == 'true')
      end
    end
    query
  end

  # Search for laboratories
  def search_laboratories(options)
    query = Laboratory.where(patient: accessible_patients)
    options.each do |option, search|
      next unless search.present?

      case option
      when 'subject'
        query = query.where(patient_id: search.match(%r{^Patient/(\d+)$}).to_a[1])
      when '_id'
        query = query.where(id: search)
      end
    end
    query
  end

  # Search for assessments
  def search_assessments(options)
    query = Assessment.where(patient: accessible_patients)
    options.each do |option, search|
      next unless search.present?

      case option
      when 'subject'
        query = query.where(patient_id: search.match(%r{^Patient/(\d+)$}).to_a[1])
      when '_id'
        query = query.where(id: search)
      end
    end
    query
  end

  # Search for CloseContacts
  def search_close_contacts(options)
    query = CloseContact.where(patient: accessible_patients)
    options.each do |option, search|
      next unless search.present?

      case option
      when 'patient'
        query = query.where(patient_id: search.match(%r{^Patient/(\d+)$}).to_a[1])
      when '_id'
        query = query.where(id: search)
      end
    end
    query
  end

  # Search for Vaccines
  def search_vaccines(options)
    query = Vaccine.where(patient: accessible_patients)
    options.each do |option, search|
      next unless search.present?

      case option
      when 'patient'
        query = query.where(patient_id: search.match(%r{^Patient/(\d+)$}).to_a[1])
      when '_id'
        query = query.where(id: search)
      end
    end
    query
  end

  # Get a lab result by id
  def get_laboratory(id)
    Laboratory.where(patient_id: accessible_patients).find_by(id: id)
  end

  # Get an assessment by id
  def get_assessment(id)
    Assessment.where(patient_id: accessible_patients).find_by(id: id)
  end

  # Get a CloseContact by id
  def get_close_contact(id)
    CloseContact.where(patient_id: accessible_patients).find_by(id: id)
  end

  # Get a Vaccine by id
  def get_vaccine(id)
    Vaccine.where(patient_id: accessible_patients).find_by(id: id)
  end

  # Construct a full url via a request and resource
  def full_url_helper(resource)
    "#{root_url}fhir/r4/#{resource.class.name.split('::').last}/#{resource.id}"
  end

  # Generate pagination links for searchset bundle
  def bundle_search_links(page, page_size, resources, resource_type, search_params)
    total = resources.size
    last_page = (total.to_f / page_size).ceil
    [
      page != 1 && total > page_size ?
        FHIR::Bundle::Link.new(relation: 'first', url: bundle_search_link_url(search_params, resource_type, 1)) : nil,
      page > 1 && total > page_size && page - 1 < last_page ?
        FHIR::Bundle::Link.new(relation: 'previous', url: bundle_search_link_url(search_params, resource_type, page - 1)) : nil,
      page < last_page && total > (page_size * page) ?
        FHIR::Bundle::Link.new(relation: 'next', url: bundle_search_link_url(search_params, resource_type, page + 1)) : nil,
      page != last_page && total > (page_size * page) ?
        FHIR::Bundle::Link.new(relation: 'last', url: bundle_search_link_url(search_params, resource_type, last_page)) : nil
    ].reject(&:nil?)
  end

  # Generate a searchset bundle link url
  def bundle_search_link_url(search_params, resource_type, target_page)
    param_str = ''
    index = 0
    search_params.each do |option, search|
      param_str += "#{index.zero? ? '?' : '&'}#{option}=#{search}"
      index += 1
    end
    param_str += "#{index.zero? ? '?' : '&'}page=#{target_page}"
    "#{root_url}fhir/r4/#{resource_type}#{param_str}"
  end

  # Operation outcome response
  def operation_outcome_fatal
    FHIR::OperationOutcome.new(issue: [FHIR::OperationOutcome::Issue.new(severity: 'fatal', code: 'processing')])
  end

  # Generate an operation outcome with error information
  def operation_outcome_with_errors(errors)
    outcome = FHIR::OperationOutcome.new(issue: [])
    errors.each { |error| outcome.issue << FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'processing', diagnostics: error) }
    outcome
  end

  # Convert to array of error strings given nested hash with arrays of error strings as values
  def format_fhir_validation_errors(errors)
    errors&.values&.each_with_object([]) do |value, messages|
      value.each do |val|
        val.is_a?(Hash) ? messages.push(*format_fhir_validation_errors(val)) : messages << val
      end
    end
  end

  # Allow cross-origin requests
  def cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Headers'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
  end
end
# rubocop:enable Metrics/ClassLength
