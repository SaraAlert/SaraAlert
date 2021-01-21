# frozen_string_literal: true

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
      :'system/Patient.*'
    )
  end
  before_action only: %i[show search] do
    doorkeeper_authorize!(
      :'user/Patient.read',
      :'user/Patient.*',
      :'user/Observation.read',
      :'user/QuestionnaireResponse.read',
      :'system/Patient.read',
      :'system/Patient.*',
      :'system/Observation.read',
      :'system/QuestionnaireResponse.read'
    )
  end
  before_action :check_client_type

  # Return a resource given a type and an id.
  #
  # Supports (reading): Patient, Observation, QuestionnaireResponse
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
    else
      status_not_found && return
    end

    status_forbidden && return if resource.nil?

    status_ok(resource.as_fhir) && return
  rescue StandardError
    render json: operation_outcome_fatal.to_json, status: :internal_server_error
  end

  # Update a resource given a type and an id.
  #
  # Supports (updating): Patient
  #
  # PUT /fhir/r4/[:resource_type]/[:id]
  def update
    if request.patch?
      status_unsupported_media_type && return unless content_type_header?('application/json-patch+json')

      # Parse in the JSON patch
      patch = Hana::Patch.new(JSON.parse(request.body.string))
    else
      status_unsupported_media_type && return unless content_type_header?('application/fhir+json')

      # Parse in the FHIR::Patient
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
      request_updates = patient_from_fhir(contents, default_patient_jurisdiction_id)
      status_unprocessable_entity && return if request_updates.nil?

      # Assign any remaining updates to the patient
      # NOTE: The patient.update method does not allow a context to be passed, so first we assign the updates, then save
      patient.assign_attributes(request_updates)

      # Wrap updates to the Patient, Transfer creation, and History creation in a transaction
      # so that they occur atomically
      ActiveRecord::Base.transaction do
        # Verify that the updated jurisdiction and other updates are valid
        unless jurisdiction_valid_for_update?(patient) && patient.save(context: :api)
          status_unprocessable_entity(format_model_validation_errors(patient)) && return
        end

        # If the jurisdiction was changed, create a Transfer
        if request_updates&.keys&.include?(:jurisdiction_id) && !request_updates[:jurisdiction_id].nil?
          Transfer.create!(patient: patient, from_jurisdiction: patient_before.jurisdiction, to_jurisdiction: patient.jurisdiction, who: @current_actor)
        end

        # Handle creating history items based on all of the updates
        update_all_patient_history(request_updates, patient_before, patient)
      end

      status_ok(patient.as_fhir) && return
    else
      status_not_found && return
    end
  rescue JSON::ParserError
    status_bad_request(['Invalid JSON in request body'])
  rescue StandardError
    render json: operation_outcome_fatal.to_json, status: :internal_server_error
  end

  # Create History items corresponding to Patient changes from an update.
  #
  # updates - A hash that contains attributes corresponding to the Patient.
  # patient_before - The Patient before updates were applied.
  # patient - The Patient after the updates have been applied.
  def update_all_patient_history(updates, patient_before, patient)
    created_by_label = "#{@m2m_workflow ? current_client_application&.name : current_resource_owner&.email} (API)"

    # Handle History for monitoree details information updates
    info_updates = updates.filter { |attr, _value| PatientHelper.info_fields.include?(attr) }
    Patient.detailed_history_edit(patient_before, patient, info_updates&.keys, created_by_label)

    # Handle History for monitoree monitoring information updates
    history_data = {
      created_by: created_by_label,
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
  # Supports (writing): Patient
  #
  # POST /fhir/r4/[:resource_type]
  def create
    status_unsupported_media_type && return unless content_type_header?('application/fhir+json')

    # Parse in the FHIR::Patient
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
      resource = Patient.new(patient_from_fhir(contents, default_patient_jurisdiction_id))
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
    else
      status_not_found && return
    end

    status_bad_request && return if resource.nil?

    unless jurisdiction_valid_for_client?(resource) && resource.save(context: :api)
      status_unprocessable_entity(format_model_validation_errors(resource)) && return
    end

    if resource_type == 'patient'
      # Send enrollment notification only to responders
      resource.send_enrollment_notification if resource.self_reporter_or_proxy?

      # Create a history for the enrollment
      History.enrollment(patient: resource, created_by: resource.creator&.email, comment: 'Monitoree enrolled via API.')
    end
    status_created(resource.as_fhir) && return
  rescue JSON::ParserError
    status_bad_request(['Invalid JSON in request body'])
  rescue StandardError
    render json: operation_outcome_fatal.to_json, status: :internal_server_error
  end

  # Return a FHIR Bundle containing results that match the given query.
  #
  # Supports (searching): Patient, Observation, QuestionnaireResponse
  #
  # GET /fhir/r4/[:resource_type]?parameter(s)
  def search
    status_not_acceptable && return unless accept_header?

    resource_type = params.permit(:resource_type)[:resource_type]&.downcase
    search_params = params.slice('family', 'given', 'telecom', 'email', 'subject', 'active',
                                 '_count', '_id')
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
  rescue StandardError
    render json: operation_outcome_fatal.to_json, status: :internal_server_error
  end

  # Return a FHIR Bundle containing a monitoree and all their assessments and
  # lab results.
  #
  # GET /fhir/r4/Patient/[:id]/$everything
  def all
    # Require all scopes for all three resources
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

    status_not_acceptable && return unless accept_header?

    patient = get_patient(params.permit(:id)[:id])

    status_forbidden && return if patient.nil?

    # Gather assessments and lab results
    assessments = patient.assessments || []
    laboratories = patient.laboratories || []
    all = [patient] + assessments.to_a + laboratories.to_a
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
  rescue StandardError
    render json: operation_outcome_fatal.to_json, status: :internal_server_error
  end

  # Return a FHIR::CapabilityStatement
  #
  # GET /fhir/r4/metadata
  def capability_statement
    resource = FHIR::CapabilityStatement.new(
      status: 'active',
      kind: 'instance',
      date: DateTime.parse('2020-05-28').strftime('%FT%T%:z'),
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
  rescue StandardError
    render json: operation_outcome_fatal.to_json, status: :internal_server_error
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
        'system/Patient.read',
        'system/Patient.write',
        'system/Patient.*',
        'system/Observation.read',
        'system/QuestionnaireResponse.read'
      ],
      capabilities: ['launch-standalone']
    }
  end

  # Handle OPTIONS requests for CORS preflight
  def options
    render plain: ''
  end

  private

  # Check whether client is user or M2M flow, set instance variables appropriately.
  # Also return a 401 if user doesn't have API access
  def check_client_type
    return if doorkeeper_token.nil?

    if current_resource_owner.present?
      if current_resource_owner.can_use_api?
        @user_workflow = true
        @current_actor = current_resource_owner
        nil
      else
        head :unauthorized
      end
    elsif current_client_application.present?
      @m2m_workflow = true

      # Actor is client application - need to get created proxy user
      proxy_user = User.where(is_api_proxy: true).find_by(id: current_client_application.user_id)
      head :unauthorized if proxy_user.nil?
      @current_actor = proxy_user
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

  def status_unprocessable_entity(errors = [])
    respond_to do |format|
      format.any { render json: errors.blank? ? operation_outcome_fatal.to_json : operation_outcome_with_errors(errors).to_json, status: :unprocessable_entity }
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
      case option
      when 'family'
        query = query.where('last_name like ?', "%#{search}%") if search.present?
      when 'given'
        query = query.where('first_name like ?', "%#{search}%") if search.present?
      when 'telecom'
        query = query.where('primary_telephone like ?', Phonelib.parse(search, 'US').full_e164) if search.present?
      when 'email'
        query = query.where('email like ?', "%#{search}%") if search.present?
      when '_id'
        query = query.where(id: search) if search.present?
      when 'active'
        query = query.where(monitoring: search == 'true') if search.present?
      end
    end
    query
  end

  # Search for laboratories
  def search_laboratories(options)
    query = Laboratory.where(patient: accessible_patients)
    options.each do |option, search|
      case option
      when 'subject'
        query = accessible_patients.find_by(id: search.split('/')[-1])&.laboratories if search.present?
      when '_id'
        query = query.where(id: search) if search.present?
      end
    end
    query
  end

  # Search for assessments
  def search_assessments(options)
    query = Assessment.where(patient: accessible_patients)
    options.each do |option, search|
      case option
      when 'subject'
        query = accessible_patients.find_by(id: search.split('/')[-1])&.assessments if search.present?
      when '_id'
        query = query.where(id: search) if search.present?
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

  def format_model_validation_errors(resource)
    resource.errors&.messages&.each_with_object([]) do |(attribute, errors), messages|
      value = resource[attribute] || resource.public_send("#{attribute}_before_type_cast")
      msg_header = 'Validation Error' + (value ? " for value '#{value}'" : '') + " on '#{VALIDATION[attribute][:label]}':"
      errors.each do |error_message|
        messages << "#{msg_header} #{error_message}"
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
