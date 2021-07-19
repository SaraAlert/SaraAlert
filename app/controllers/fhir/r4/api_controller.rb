# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

# ApiController: API for interacting with Sara Alert
class Fhir::R4::ApiController < ApplicationApiController
  include ValidationHelper
  include FhirHelper
  include ActionController::MimeResponds

  before_action :cors_headers
  before_action only: %i[create update transaction] do
    doorkeeper_authorize!(
      *PATIENT_WRITE_SCOPES,
      *RELATED_PERSON_WRITE_SCOPES,
      *IMMUNIZATION_WRITE_SCOPES,
      *OBSERVATION_WRITE_SCOPES
    )
  end
  before_action only: %i[show search] do
    doorkeeper_authorize!(
      *PATIENT_READ_SCOPES,
      *RELATED_PERSON_READ_SCOPES,
      *IMMUNIZATION_READ_SCOPES,
      *OBSERVATION_READ_SCOPES,
      *QUESTIONNAIRE_RESPONSE_READ_SCOPES,
      *PROVENANCE_READ_SCOPES
    )
  end
  before_action :check_client_type
  rescue_from StandardError, with: :handle_server_error
  rescue_from ClientError, with: proc {}

  MAX_TRANSACTION_ENTRIES = 50

  # Return a resource given a type and an id.
  #
  # Supports (reading): Patient, Observation, QuestionnaireResponse, RelatedPerson, Immunization, Provenance
  #
  # GET /fhir/r4/[:resource_type]/[:id]
  def show
    status_not_acceptable && return unless accept_header?

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      return if doorkeeper_authorize!(*PATIENT_READ_SCOPES)

      resource = get_patient(params.permit(:id)[:id])
    when 'observation'
      return if doorkeeper_authorize!(*OBSERVATION_READ_SCOPES)

      resource = get_record(Laboratory, params.permit(:id)[:id])
    when 'questionnaireresponse'
      return if doorkeeper_authorize!(*QUESTIONNAIRE_RESPONSE_READ_SCOPES)

      resource = get_record(Assessment, params.permit(:id)[:id])
    when 'relatedperson'
      return if doorkeeper_authorize!(*RELATED_PERSON_READ_SCOPES)

      resource = get_record(CloseContact, params.permit(:id)[:id])
    when 'immunization'
      return if doorkeeper_authorize!(*IMMUNIZATION_READ_SCOPES)

      resource = get_record(Vaccine, params.permit(:id)[:id])
    when 'provenance'
      return if doorkeeper_authorize!(*PROVENANCE_READ_SCOPES)

      resource = get_record(History, params.permit(:id)[:id])
    else
      status_not_found && return
    end

    status_forbidden && return if resource.nil?

    status_ok(resource.as_fhir) && return
  end

  # Update a resource given a type and an id.
  #
  # Supports (updating): Patient, RelatedPerson, Immunization, Observation
  #
  # PUT /fhir/r4/[:resource_type]/[:id]
  def update
    if request.patch?
      status_unsupported_media_type && return unless content_type_header?('application/json-patch+json')

      # Parse in the JSON patch
      request_body = request.body.read
      patch = Hana::Patch.new(JSON.parse(request_body))
    else
      status_unsupported_media_type && return unless content_type_header?('application/fhir+json')

      # Parse in the FHIR
      request_body = request.body.read
      contents = FHIR.from_contents(request_body) unless request_body.blank?
      errors = contents&.validate
      status_bad_request(format_fhir_validation_errors(errors)) && return if contents.nil? || !errors.empty?
    end

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      return if doorkeeper_authorize!(*PATIENT_WRITE_SCOPES)

      # Get the patient that needs to be updated
      patient = get_patient(params.permit(:id)[:id])
      status_forbidden && return if patient.nil?

      # Get the contents from applying a patch, if needed
      contents = apply_patch(patient, patch) if request.patch?

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
          req_json = request.patch? ? patient.as_fhir.to_json : JSON.parse(request_body)
          status_unprocessable_entity(patient, fhir_map, req_json) && return
        end

        # If the jurisdiction was changed, create a Transfer
        if request_updates&.keys&.include?(:jurisdiction_id) &&
           !request_updates[:jurisdiction_id].nil? &&
           patient_before.jurisdiction_id != patient.jurisdiction_id
          Transfer.create!(patient: patient, from_jurisdiction: patient_before.jurisdiction, to_jurisdiction: patient.jurisdiction, who: @current_actor)
        end

        # Handle creating history items based on all of the updates
        update_all_patient_history(request_updates, patient_before, patient)
      end

      status_ok(patient.as_fhir) && return
    when 'relatedperson'
      return if doorkeeper_authorize!(*RELATED_PERSON_WRITE_SCOPES)

      # Get the CloseContact that needs to be updated
      close_contact = get_record(CloseContact, params.permit(:id)[:id])
      status_forbidden && return if close_contact.nil?

      # Get the contents from applying a patch, if needed
      contents = apply_patch(close_contact, patch) if request.patch?

      update_record(*update_model_from_fhir(close_contact, contents, :close_contact_from_fhir), request_body, :close_contact_edit, 'close contact')

      status_ok(close_contact.as_fhir) && return
    when 'immunization'
      return if doorkeeper_authorize!(*IMMUNIZATION_WRITE_SCOPES)

      # Get the Vaccine that needs to be updated
      vaccine = get_record(Vaccine, params.permit(:id)[:id])
      status_forbidden && return if vaccine.nil?

      # Get the contents from applying a patch, if needed
      contents = apply_patch(vaccine, patch) if request.patch?

      update_record(*update_model_from_fhir(vaccine, contents, :vaccine_from_fhir), request_body, :vaccination_edit, 'vaccination')

      status_ok(vaccine.as_fhir) && return
    when 'observation'
      return if doorkeeper_authorize!(*OBSERVATION_WRITE_SCOPES)

      # Get the Lab that needs to be updated
      lab = get_record(Laboratory, params.permit(:id)[:id])
      status_forbidden && return if lab.nil?

      # Get the contents from applying a patch, if needed
      contents = apply_patch(lab, patch) if request.patch?

      update_record(*update_model_from_fhir(lab, contents, :laboratory_from_fhir), request_body, :lab_result_edit, 'lab result')

      status_ok(lab.as_fhir) && return
    else
      status_not_found && return
    end
  rescue JSON::ParserError
    status_bad_request(['Invalid JSON in request body'])
  end

  # Create a resource given a type.
  #
  # Supports (writing): Patient, RelatedPerson, Immunization, Observation
  #
  # POST /fhir/r4/[:resource_type]
  def create
    status_unsupported_media_type && return unless content_type_header?('application/fhir+json')

    # Parse in the FHIR
    request_body = request.body.read
    contents = FHIR.from_contents(request_body) unless request_body.blank?
    errors = contents&.validate
    status_bad_request(format_fhir_validation_errors(errors)) && return if contents.nil? || !errors.empty?

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    case resource_type
    when 'patient'
      return if doorkeeper_authorize!(*PATIENT_WRITE_SCOPES)

      resource = save_patient(*build_patient(contents), request_body)
    when 'relatedperson'
      return if doorkeeper_authorize!(*RELATED_PERSON_WRITE_SCOPES)

      resource = save_record(*build_model_from_fhir(CloseContact, contents, :close_contact_from_fhir), request_body, :close_contact, 'close contact')
    when 'immunization'
      return if doorkeeper_authorize!(*IMMUNIZATION_WRITE_SCOPES)

      resource = save_record(*build_model_from_fhir(Vaccine, contents, :vaccine_from_fhir), request_body, :vaccination, 'vaccination')
    when 'observation'
      return if doorkeeper_authorize!(*OBSERVATION_WRITE_SCOPES)

      resource = save_record(*build_model_from_fhir(Laboratory, contents, :laboratory_from_fhir), request_body, :lab_result, 'lab result')
    else
      status_not_found && return
    end
    status_created(resource.as_fhir) && return
  rescue JSON::ParserError
    status_bad_request(['Invalid JSON in request body'])
  end

  # Create a set of resources as an atomic action
  #
  # Supports (writing): Patient, Observation
  #
  # POST /fhir/r4
  def transaction
    status_unsupported_media_type && return unless content_type_header?('application/fhir+json')

    # Must have Patient write scopes
    return if doorkeeper_authorize!(*PATIENT_WRITE_SCOPES)

    # Parse in the FHIR
    request_body = request.body.read
    contents = FHIR.from_contents(request_body) unless request_body.blank?

    # Only allow a maximum batch size of MAX_TRANSACTION_ENTRIES
    if !contents&.entry.nil? && contents.entry.length > MAX_TRANSACTION_ENTRIES
      status_unprocessable_entity_with_custom_errors(
        ["Bundle.entry can contain at most #{MAX_TRANSACTION_ENTRIES} entries"],
        'Bundle.entry'
      ) && return
    end

    errors = contents&.validate
    status_bad_request(format_fhir_validation_errors(errors)) && return if contents.nil? || !errors.empty?

    # Validate that we can go forward with processing the Bundle
    error, path = validate_transaction_bundle(contents)
    status_unprocessable_entity_with_custom_errors([error], path) && return unless error.nil?

    # Transform all the Patients from FHIR
    patients = []
    contents.entry&.each_with_index do |entry, index|
      next unless entry.resource&.resourceType&.downcase == 'patient'

      resource, fhir_map = build_patient(entry&.resource)
      change_fhir_map_context!(fhir_map, 'Patient', "Bundle.entry[#{index}].resource")
      patients << { resource: resource, fhir_map: fhir_map, full_url: entry.fullUrl }
    end

    # Transform all of the Laboratories from FHIR
    authorized = false
    contents.entry&.each_with_index do |entry, index|
      next unless entry.resource&.resourceType&.downcase == 'observation'

      # If there are Observations, ensure user is authorized to write them
      return if !authorized && doorkeeper_authorize!(*OBSERVATION_WRITE_SCOPES)

      authorized = true

      # We require that each Observation references a Patient in the same Bundle
      referenced_patient = patients.find { |p| p[:full_url] == entry.resource&.subject&.reference }&.dig(:resource)
      if referenced_patient.nil?
        status_unprocessable_entity_with_custom_errors(
          ['Observation resources must reference the fullUrl of a Patient in the same Bundle'],
          "Bundle.entry[#{index}].resource.subject.reference"
        ) && return
      end

      resource, fhir_map = build_model_from_fhir(Laboratory, entry&.resource, :laboratory_from_fhir)
      change_fhir_map_context!(fhir_map, 'Observation', "Bundle.entry[#{index}].resource")
      referenced_patient.laboratories << resource
      # Laboratory must be validated here since errors are inaccessible when saving Patient
      unless resource.valid?(:api) && fhir_map.all? { |_k, v| v[:errors].blank? }
        req_json = JSON.parse(request_body)
        status_unprocessable_entity(resource, fhir_map, req_json) && return
      end
    end

    # Save each Patient, along with its corresponding Labs
    saved_patients = []
    ActiveRecord::Base.transaction do
      patients.each do |patient|
        saved_patients << save_patient(patient[:resource], patient[:fhir_map], request_body)
      end
    end

    # Generate the Bundle and return
    status_ok(patients_to_fhir_bundle(saved_patients)) && return
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
      return if doorkeeper_authorize!(*PATIENT_READ_SCOPES)

      resources = search_patients(search_params)
      resource_type = 'Patient'
    when 'observation'
      return if doorkeeper_authorize!(*OBSERVATION_READ_SCOPES)

      resources = search_laboratories(search_params) || []
      resource_type = 'Observation'
    when 'questionnaireresponse'
      return if doorkeeper_authorize!(*QUESTIONNAIRE_RESPONSE_READ_SCOPES)

      resources = search_assessments(search_params) || []
      resource_type = 'QuestionnaireResponse'
    when 'relatedperson'
      return if doorkeeper_authorize!(*RELATED_PERSON_READ_SCOPES)

      resources = search_close_contacts(search_params) || []
      resource_type = 'RelatedPerson'
    when 'immunization'
      return if doorkeeper_authorize!(*IMMUNIZATION_READ_SCOPES)

      resources = search_vaccines(search_params) || []
      resource_type = 'Immunization'
    when 'provenance'
      return if doorkeeper_authorize!(*PROVENANCE_READ_SCOPES)

      resources = search_histories(search_params) || []
      resource_type = 'Provenance'
    else
      status_not_found && return
    end

    page_size = params.permit(:_count)[:_count].nil? ? 10 : params.permit(:_count)[:_count].to_i
    page_size = 500 if page_size > 500
    summary_mode = page_size.zero?
    page = params.permit(:page)[:page].to_i
    page = 1 if page.zero?
    entries = resources.size
    unless summary_mode
      results = resources.paginate(per_page: page_size, page: page).collect do |r|
        r_as_fhir = r.as_fhir
        FHIR::Bundle::Entry.new(fullUrl: full_url_helper(r_as_fhir), resource: r_as_fhir)
      end
    end

    # Construct bundle from search query
    bundle = FHIR::Bundle.new(
      id: SecureRandom.uuid,
      meta: FHIR::Meta.new(lastUpdated: DateTime.now.strftime('%FT%T%:z')),
      type: 'searchset',
      total: entries,
      link: summary_mode ? nil : bundle_search_links(page, page_size, resource_type, search_params, entries),
      entry: results || []
    )

    status_ok(bundle) && return
  end

  # Return a FHIR Bundle containing a monitoree and all their assessments, lab results,
  # close contacts, vaccinations, and histories
  #
  # GET /fhir/r4/Patient/[:id]/$everything
  def all
    # Require all scopes for all five resources
    return if doorkeeper_authorize!(*PATIENT_READ_SCOPES)
    return if doorkeeper_authorize!(*OBSERVATION_READ_SCOPES)
    return if doorkeeper_authorize!(*QUESTIONNAIRE_RESPONSE_READ_SCOPES)
    return if doorkeeper_authorize!(*RELATED_PERSON_READ_SCOPES)
    return if doorkeeper_authorize!(*IMMUNIZATION_READ_SCOPES)
    return if doorkeeper_authorize!(*PROVENANCE_READ_SCOPES)

    status_not_acceptable && return unless accept_header?

    patient = get_patient(params.permit(:id)[:id])

    status_forbidden && return if patient.nil?

    # Gather assessments, labs, close contacts, and vaccines
    assessments = patient.assessments || []
    laboratories = patient.laboratories || []
    close_contacts = patient.close_contacts || []
    vaccines = patient.vaccines || []
    histories = patient.histories || []
    all = [patient] + assessments + laboratories + close_contacts + vaccines + histories
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

  # Kick off async generation of bulk FHIR data for all accessible patients
  #
  # GET /fhir/r4/Patient/$export
  def bulk_data_export
    # Require all scopes for all possible resources being returned
    return if doorkeeper_authorize!(*PATIENT_READ_SCOPES)
    return if doorkeeper_authorize!(*OBSERVATION_READ_SCOPES)
    return if doorkeeper_authorize!(*QUESTIONNAIRE_RESPONSE_READ_SCOPES)
    return if doorkeeper_authorize!(*RELATED_PERSON_READ_SCOPES)
    return if doorkeeper_authorize!(*IMMUNIZATION_READ_SCOPES)
    return if doorkeeper_authorize!(*PROVENANCE_READ_SCOPES)

    unless accept_header?
      status_not_acceptable_with_custom_errors(["'Accept' header must have a value of 'application/fhir+json'," \
        " or the '_format' parameter must be one of 'json', 'application/json' or 'application/fhir+json'"]) && return
    end

    unless prefer_header?
      status_unprocessable_entity_with_custom_errors(["'Prefer' header must have value of 'respond-async'"],
                                                     '') && return
    end

    unless @m2m_workflow
      status_unauthorized_with_custom_errors(['Bulk export requires a client application registered for the Backend Services Workflow']) && return
    end

    if params.key?(:_type) || params.key?(:_outputFormat)
      status_unprocessable_entity_with_custom_errors(['The _type and _outputFormat parameters are unsupported'], '') && return
    end

    begin
      since = params.permit(:_since)[:_since]
      since = DateTime.strptime(since, '%Y-%m-%dT%H:%M:%S%z') unless since.blank?
    rescue Date::Error
      status_unprocessable_entity_with_custom_errors(['Invalid Date in _since parameter. Please use the FHIR instant datatype'], '') && return
    end

    client_app = current_client_application
    if client_app.exported_recently?
      status_too_many_requests_with_custom_errors(['Client already initiated an export of this type in the last 15 minutes. Please try again later']) && return
    end

    # Create the download to uniquely id this request, and queue the ExportFhirJob
    download = ApiDownload.create(application_id: client_app.id, url: request.url)
    export_job = ExportFhirJob.perform_later(client_app, download, { since: since })
    # Add the job_id of the job to the download for reference in status requests
    download.update(job_id: export_job.provider_job_id)

    respond_to do |format|
      format.any { head(:accepted, content_location: "#{root_url}fhir/r4/ExportStatus/#{download.id}") }
    end
  end

  # Give an update on the status of a bulk FHIR data request
  #
  # GET /fhir/r4/ExportStatus/[:id]
  def export_status
    id = params.require(:id)
    download = ApiDownload.find_by_id(id)
    status = Sidekiq::Status.status(download&.job_id)
    case status
    when :complete
      begin
        transaction_time = DateTime.parse(Sidekiq::Status.get(download.job_id, :transaction_time))
      rescue Date::Error
        status_server_error(['Export failed']) && return
      end

      response_json = {
        transactionTime: transaction_time.utc.strftime('%FT%T%:z'),
        request: download.url,
        requiresAccessToken: true,
        output: download.files.blobs.pluck(:filename).map do |file|
          resource_type = file.split('.').first
          {
            type: resource_type,
            url: "#{root_url}fhir/r4/ExportFiles/#{id}/#{resource_type}"
          }
        end
      }
      response.headers['Expires'] = Chronic.parse(ADMIN_OPTIONS['weekly_purge_date']).httpdate
      render json: response_json.to_json, status: :ok
    when :failed
      status_server_error(['Export failed']) && return
    when :working, :queued, :retrying
      response.headers['X-Progress'] = status.to_s
      head :accepted
    else
      status_not_found_with_custom_errors(['No export found for this ID']) && return
    end
  end

  # Return an bulk exported ndjson file
  #
  # GET /ExportFiles/[:id]/[:resource_type]
  def export_files
    unless request.headers['Accept'].nil? || request.headers['Accept'] == 'application/fhir+ndjson'
      status_not_acceptable_with_custom_errors(["'Accept' header must have a value of 'application/fhir+ndjson'"]) && return
    end

    id = params.require(:id)
    resource_type = params.require(:resource_type)&.downcase
    authorize_resource_type_read(resource_type)

    download = current_client_application&.api_downloads&.find_by_id(id)
    status_not_found_with_custom_errors(['No file found at this URL']) && return if download.nil?

    # Set the headers before streaming the returned content
    response.headers['Content-Type'] = 'application/fhir+ndjson'
    # Find and return the specific attachment associated with the given filename
    download.files.blobs.where(filename: "#{resource_type}.ndjson").first.download do |chunk|
      response.stream.write chunk
    end
  ensure
    response.stream.close
  end

  # Return a FHIR::CapabilityStatement
  #
  # GET /fhir/r4/metadata
  def capability_statement
    resource = FHIR::CapabilityStatement.new(
      status: 'active',
      kind: 'instance',
      date: DateTime.parse('2021-05-04').strftime('%FT%T%:z'),
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
            type: 'Immunization',
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
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'update'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'patch'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'create'),
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
          ),
          FHIR::CapabilityStatement::Rest::Resource.new(
            type: 'Provenance',
            interaction: [
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'read'),
              FHIR::CapabilityStatement::Rest::Resource::Interaction.new(code: 'search-type')
            ],
            searchParam: [
              FHIR::CapabilityStatement::Rest::Resource::SearchParam.new(name: 'patient', type: 'reference'),
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
        'user/Observation.*',
        'user/QuestionnaireResponse.read',
        'user/RelatedPerson.read',
        'user/RelatedPerson.write',
        'user/RelatedPerson.*',
        'user/Immunization.read',
        'user/Immunization.write',
        'user/Immunization.*',
        'user/Provenance.read',
        'system/Patient.read',
        'system/Patient.write',
        'system/Patient.*',
        'system/Observation.read',
        'system/Observation.*',
        'system/QuestionnaireResponse.read',
        'system/RelatedPerson.read',
        'system/RelatedPerson.write',
        'system/RelatedPerson.*',
        'system/Immunization.read',
        'system/Immunization.write',
        'system/Immunization.*',
        'system/Provenance.read'
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

    # query current_resource_owner and current_client_application from db only once
    resource_owner = current_resource_owner
    client_application = current_client_application unless resource_owner.present?

    if resource_owner.present?
      Rails.logger.info "Client: User, ID: #{resource_owner.id}, Email: #{resource_owner.email}"
      if resource_owner.can_use_api?
        @user_workflow = true
        @current_actor = resource_owner
        @current_actor_label = "#{resource_owner.email} (API)"
        nil
      else
        status_unauthorized
      end
    elsif client_application.present?
      Rails.logger.info "Client: Application, ID: #{client_application.id}, Name: #{client_application.name}"
      @m2m_workflow = true

      # Actor is client application - need to get created proxy user
      proxy_user = User.where(is_api_proxy: true).find_by(id: client_application.user_id)
      status_unauthorized if proxy_user.nil?
      @current_actor = proxy_user
      @current_actor_label = "#{client_application.name} (API)"
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
  rescue StandardError => e
    status_bad_request([['Unable to apply patch', e&.message].compact.join(': ')]) && (raise ClientError)
  end

  # Check accept header for correct mime type (or allow fhir _format)
  def accept_header?
    return request.headers['Accept']&.include?('application/fhir+json') if params.permit(:_format)[:_format].nil?

    ['json', 'application/json', 'application/fhir+json'].include?(params.permit(:_format)[:_format]&.downcase)
  end

  # Check prefer header for correct value
  def prefer_header?
    request.headers['Prefer']&.include?('respond-async')
  end

  # Check content type header for correct mime type
  def content_type_header?(header)
    request.content_type == header
  end

  # Generic 400 bad request response
  def status_bad_request(errors = [])
    respond_to do |format|
      format.any { render json: errors.blank? ? operation_outcome_fatal.to_json : operation_outcome_with_errors(errors).to_json, status: :bad_request }
    end
  end

  # Generic 404 not found response
  def status_not_found(errors = [])
    respond_to do |format|
      format.any { render json: errors.blank? ? operation_outcome_fatal.to_json : operation_outcome_with_errors(errors).to_json, status: :not_found }
    end
  end

  # 406 not acceptable status with custom error messages
  def status_not_acceptable_with_custom_errors(errors = [])
    respond_to do |format|
      format.any { render json: errors.blank? ? operation_outcome_fatal.to_json : operation_outcome_with_errors(errors).to_json, status: :not_acceptable }
    end
  end

  # 401 unauthorized with custom error messages
  def status_unauthorized_with_custom_errors(errors = [])
    respond_to do |format|
      format.any { render json: errors.blank? ? operation_outcome_fatal.to_json : operation_outcome_with_errors(errors).to_json, status: :unauthorized }
    end
  end

  # 404 not found with custom error messages
  def status_not_found_with_custom_errors(errors = [])
    respond_to do |format|
      format.any { render json: errors.blank? ? operation_outcome_fatal.to_json : operation_outcome_with_errors(errors).to_json, status: :not_found }
    end
  end

  # 429 too many requests with custom error messages
  def status_too_many_requests_with_custom_errors(errors = [])
    respond_to do |format|
      format.any { render json: errors.blank? ? operation_outcome_fatal.to_json : operation_outcome_with_errors(errors).to_json, status: :too_many_requests }
    end
  end

  # 500 server error status with custom error messages
  def status_server_error(errors = [])
    respond_to do |format|
      format.any do
        render json: errors.blank? ? operation_outcome_fatal.to_json : operation_outcome_with_errors(errors).to_json, status: :internal_server_error
      end
    end
  end

  # 422 response with custom error messages
  def status_unprocessable_entity_with_custom_errors(errors, path)
    outcome = FHIR::OperationOutcome.new(issue: [])
    errors.each do |error|
      outcome.issue << FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'processing', diagnostics: error, expression: path)
    end
    respond_to do |format|
      format.any { render json: outcome.to_json, status: :unprocessable_entity }
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
            value = pretty_print_code_from_fhir(value) if value['code'] && value['system']
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
    query.includes(:jurisdiction, :creator)
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
    query.includes({ reported_condition: :symptoms })
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

  # Search for Histories
  def search_histories(options)
    query = History.where(patient: accessible_patients)
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

  # Build a Patient and the corresponding fhir_map from FHIR contents
  def build_patient(contents)
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

    [resource, fhir_map]
  end

  # Save a Patient model
  def save_patient(resource, fhir_map, request_body)
    status_bad_request && (raise ClientError) if resource.nil?

    ActiveRecord::Base.transaction do
      unless jurisdiction_valid_for_client?(resource) && resource.save(context: %i[api api_create])
        req_json = JSON.parse(request_body)
        status_unprocessable_entity(resource, fhir_map, req_json) && (raise ClientError)
      end

      # Create a history for the enrollment
      History.enrollment(patient: resource, created_by: @current_actor_label, comment: 'Monitoree enrolled via API.')

      # And for any created laboratories
      resource.laboratories.each do |lab|
        History.lab_result(patient: resource.id,
                           created_by: @current_actor_label,
                           comment: "New lab result added via API (ID: #{lab.id}).")
      end
    end

    # This is necessary since the transaction will swallow an ActiveRecord::Rollback error
    raise(StandardError, 'Error when saving Patient to the database') if resource.id.nil?

    Rails.logger.info "Created Patient with ID: #{resource.id}"
    resource.laboratories.each do |lab|
      Rails.logger.info "Created Lab Result (ID: #{lab.id}) for Patient with ID: #{resource.id}"
    end
    # Send enrollment notification only to responders
    resource.send_enrollment_notification if resource.self_reporter_or_proxy?

    resource
  end

  # Build a non-Patient model from FHIR, given a conversion function
  def build_model_from_fhir(model, contents, from_fhir_function)
    fhir_map = method(from_fhir_function).call(contents)
    vals = fhir_map.transform_values { |v| v[:value] }
    resource = model.new(vals)

    [resource, fhir_map]
  end

  # Save a non-Patient record
  def save_record(resource, fhir_map, request_body, history_type, resource_label)
    ActiveRecord::Base.transaction do
      unless referenced_patient_valid_for_client?(resource, :patient_id) && resource.save(context: :api) && fhir_map.all? { |_k, v| v[:errors].blank? }
        req_json = JSON.parse(request_body)
        status_unprocessable_entity(resource, fhir_map, req_json) && (raise ClientError)
      end

      Rails.logger.info "Created #{resource_label} (ID: #{resource.id}) for Patient with ID: #{resource.patient_id}"
      History.send(history_type, patient: resource.patient_id,
                                 created_by: @current_actor_label,
                                 comment: "New #{resource_label} added via API (ID: #{resource.id}).")
    end
    resource
  end

  # Update a non-Patient model from FHIR, given a conversion function
  def update_model_from_fhir(resource, contents, from_fhir_function)
    fhir_map = method(from_fhir_function).call(contents)
    request_updates = fhir_map.transform_values { |v| v[:value] }
    status_unprocessable_entity && (raise ClientError) if request_updates.nil?

    resource.assign_attributes(request_updates)
    [resource, fhir_map]
  end

  # Update a non-Patient record
  def update_record(resource, fhir_map, request_body, history_type, resource_label)
    ActiveRecord::Base.transaction do
      unless referenced_patient_valid_for_client?(resource, :patient_id) && resource.save(context: :api) && fhir_map.all? { |_k, v| v[:errors].blank? }
        req_json = request.patch? ? resource.as_fhir.to_json : JSON.parse(request_body)
        status_unprocessable_entity(resource, fhir_map, req_json) && (raise ClientError)
      end

      Rails.logger.info "Updated #{resource_label} (ID: #{resource.id}) for Patient with ID: #{resource.patient_id}"
      History.send(history_type, patient: resource.patient_id,
                                 created_by: @current_actor_label,
                                 comment: "#{resource_label.capitalize} edited via the API (ID: #{resource.id}).")
    end
    resource
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
      initiator_id: patient.id,
      propagation: :none
    }
    patient.monitoring_history_edit(history_data, nil)
  end

  # Get a record that has a "patient_id" field
  def get_record(model, id)
    model.where(patient_id: accessible_patients).find_by(id: id)
  end

  # Construct a full url via a request and resource
  def full_url_helper(resource)
    "#{root_url}fhir/r4/#{resource.class.name.split('::').last}/#{resource.id}"
  end

  # Generate pagination links for searchset bundle
  def bundle_search_links(page, page_size, resource_type, search_params, total)
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

  # Check if the client application is authorized to read a given resource_type
  def authorize_resource_type_read(resource_type)
    case resource_type
    when 'patient'
      (raise ClientError) if doorkeeper_authorize!(*PATIENT_READ_SCOPES)
    when 'observation'
      (raise ClientError) if doorkeeper_authorize!(*OBSERVATION_READ_SCOPES)
    when 'questionnaireresponse'
      (raise ClientError) if doorkeeper_authorize!(*QUESTIONNAIRE_RESPONSE_READ_SCOPES)
    when 'relatedperson'
      (raise ClientError) if doorkeeper_authorize!(*RELATED_PERSON_READ_SCOPES)
    when 'immunization'
      (raise ClientError) if doorkeeper_authorize!(*IMMUNIZATION_READ_SCOPES)
    when 'provenance'
      (raise ClientError) if doorkeeper_authorize!(*PROVENANCE_READ_SCOPES)
    else
      status_not_found_with_custom_errors(["Invalid ResourceType '#{resource_type}'"]) && (raise ClientError)
    end
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
