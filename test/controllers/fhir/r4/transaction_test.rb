# frozen_string_literal: true

require 'api_controller_test_case'

class TransactionTest < ApiControllerTestCase
  setup do
    setup_system_applications
    setup_system_tokens
    setup_bundle
    setup_logger
  end

  def setup_bundle
    @bundle = FHIR::Bundle.new(
      type: 'transaction'
    )
    @bundle.entry << patient_entry('Test', 'Tester')
    @bundle.entry << observation_entry(@bundle.entry[0].fullUrl)
  end

  def patient_entry(first_name, last_name)
    patient = create(
      :patient,
      address_state: 'Oregon',
      date_of_birth: 25.years.ago,
      user_defined_id_statelocal: 'EX-930575',
      first_name: first_name,
      last_name: last_name,
      last_date_of_exposure: 4.days.ago.to_date,
      symptom_onset: 4.days.ago.to_date,
      creator: User.find_by(id: @system_everything_app.user_id)
    )
    patient.responder_id = nil

    FHIR::Bundle::Entry.new(
      fullUrl: "urn:uuid:#{SecureRandom.uuid}",
      request: FHIR::Bundle::Entry::Request.new(
        method: 'POST',
        url: 'Patient'
      ),
      resource: patient.as_fhir
    )
  end

  def observation_entry(reference)
    observation_as_fhir = create(
      :laboratory,
      lab_type: Laboratory::LAB_TYPE_TO_CODE.keys.sample,
      result: Laboratory::RESULT_TO_CODE.keys.sample,
      specimen_collection: 2.days.ago,
      report: 1.day.ago
    ).as_fhir
    observation_as_fhir.subject.reference = reference

    FHIR::Bundle::Entry.new(
      fullUrl: "urn:uuid:#{SecureRandom.uuid}",
      request: FHIR::Bundle::Entry::Request.new(
        method: 'POST',
        url: 'Observation'
      ),
      resource: observation_as_fhir
    )
  end

  test 'should be unauthorized via transaction' do
    post '/fhir/r4'
    assert_response :unauthorized
  end

  test 'should be forbidden via transaction with only Patient scope' do
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should be bad request via transaction due to invalid JSON' do
    post(
      '/fhir/r4',
      env: { 'RAW_POST_DATA' => '{ "foo", "bar" }' },
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'Invalid JSON in request body', json_response['issue'][0]['diagnostics']
  end

  test 'should be bad request via transaction due to non-FHIR' do
    post(
      '/fhir/r4',
      params: { foo: 'bar' }.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
  end

  test 'should be bad request via transaction with invalid FHIR' do
    @bundle.type = 1
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_match(/Bundle.type/, json_response['issue'][0]['diagnostics'])
  end

  test 'should be unprocessable entity via transaction with non-transaction bundle' do
    @bundle.type = 'transaction-response'
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_match(/Bundle\.type/, json_response['issue'][0]['expression'][0])
  end

  test 'should be unprocessable entity via transaction with invalid resources' do
    @bundle.entry << FHIR::Bundle::Entry.new(
      fullUrl: "urn:uuid:#{SecureRandom.uuid}",
      request: FHIR::Bundle::Entry::Request.new(
        method: 'POST',
        url: 'Person'
      ),
      resource: FHIR::Person.new
    )
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_match(/resource of type 'Observation' or 'Patient'/, json_response['issue'][0]['diagnostics'])
    assert_match(/Bundle\.entry\[2\]\.resource/, json_response['issue'][0]['expression'][0])
  end

  test 'should be unprocessable entity via transaction with invalid request' do
    @bundle.entry[0].request.local_method = 'GET'
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_match(/Invalid request method/, json_response['issue'][0]['diagnostics'])
    assert_match(/Bundle\.entry\[0\]\.request/, json_response['issue'][0]['expression'][0])
  end

  test 'should be unprocessable entity via transaction when Observation does not reference Patient in Bundle' do
    @bundle.entry[1].resource.subject.reference = 'Patient/123'
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_match(/must reference the fullUrl/, json_response['issue'][0]['diagnostics'])
    assert_match(/Bundle\.entry\[1\]\.resource\.subject\.reference/, json_response['issue'][0]['expression'][0])
  end

  test 'should be unprocessable entity via transaction when Patient is invalid' do
    @bundle.entry[0].resource.address[0].state = 'foo'
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_match(/State.*not an acceptable value/, json_response['issue'][0]['diagnostics'])
    assert_match(/Bundle\.entry\[0\]\.resource\.address\[0\]\.stat/, json_response['issue'][0]['expression'][0])
  end

  test 'should be unprocessable entity via transaction when Observation is invalid' do
    @bundle.entry[1].resource.code.coding[0].code = 'foo'
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_match(/Lab Test Type.*not an acceptable value/, json_response['issue'][0]['diagnostics'])
    assert_match(/Bundle\.entry\[1\]\.resource\.code\.coding\[0\]/, json_response['issue'][0]['expression'][0])
  end

  test 'should be unprocessable entity via transaction when duplicate detection is enabled and 1 potential duplicate is found with an Observation' do
    @bundle.entry[0].request.ifNoneExist = "identifier=http://saraalert.org/SaraAlert/state-local-id|#{@bundle.entry[0].resource.identifier[0].value}&" \
                                           "birthdate=#{@bundle.entry[0].resource.birthDate}"
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal('Observation resources must reference the fullUrl of a Patient in the same Bundle, but the Observation referenced the fullUrl of a Patient ' \
                 'with one existing duplicate.', json_response['issue'][0]['diagnostics'])
    assert_match(/Bundle\.entry\[1\]\.resource\.subject\.reference/, json_response['issue'][0]['expression'][0])
  end

  test 'should be ok via transaction when duplicate detection is enabled and 1 potential duplicate is found' do
    @bundle.entry[0].request.ifNoneExist = "identifier=http://saraalert.org/SaraAlert/state-local-id|#{@bundle.entry[0].resource.identifier[0].value}&" \
                                           "birthdate=#{@bundle.entry[0].resource.birthDate}"
    @bundle.entry[1] = nil
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal(@bundle.entry[0].fullUrl, json_response['entry'][0]['fullUrl'])
    assert_equal('200 OK', json_response['entry'][0]['response']['status'])
  end

  test 'should be precondition failed via transaction when duplicate detection is enabled and multiple potential duplicates are found' do
    @bundle.entry[0].request.ifNoneExist = "birthdate=#{@bundle.entry[0].resource.birthDate}"
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :precondition_failed
    json_response = JSON.parse(response.body)
    assert_match(/There are #{Patient.where(date_of_birth: @bundle.entry[0].resource.birthDate).size} potential duplicate patients/,
                 json_response['issue'][0]['diagnostics'])
    assert_equal(['Bundle.entry[0].resource'], json_response['issue'][0]['expression'])
  end

  test 'should create a Patient and Observation via transaction' do
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :ok
    json_response = JSON.parse(response.body)

    patient_json = json_response['entry'][0]['resource']
    original_json = JSON.parse(@bundle.to_json)['entry'][0]['resource']
    assert_equal original_json.except('id', 'meta', 'contained', 'extension'), patient_json.except('id', 'meta', 'contained', 'extension')
    # Response JSON may include additional extensions, but should contain every original extension
    assert(original_json['extension'].all? { |e| patient_json['extension'].include?(e) })

    observation_json = json_response['entry'][1]['resource']
    original_json = JSON.parse(@bundle.to_json)['entry'][1]['resource']
    assert_equal original_json.except('id', 'meta', 'subject', 'extension'), observation_json.except('id', 'meta', 'subject', 'extension')

    created_patient_id = patient_json['id']
    created_lab_id = observation_json['id']
    created_patient = Patient.find_by(id: created_patient_id.to_i)
    assert_not_nil created_patient
    assert_equal 1, created_patient.laboratories.count
    assert_equal created_lab_id, created_patient.laboratories[0].id
  end

  test 'should create a Patient and multiple Observations via transaction' do
    @bundle.entry << observation_entry(@bundle.entry[0].fullUrl)
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :ok
    json_response = JSON.parse(response.body)

    patient_json = json_response['entry'][0]['resource']
    original_json = JSON.parse(@bundle.to_json)['entry'][0]['resource']
    assert_equal original_json.except('id', 'meta', 'contained', 'extension'), patient_json.except('id', 'meta', 'contained', 'extension')
    # Response JSON may include additional extensions, but should contain every original extension
    assert(original_json['extension'].all? { |e| patient_json['extension'].include?(e) })

    created_patient_id = patient_json['id']
    created_patient = Patient.find_by(id: created_patient_id.to_i)
    assert_not_nil created_patient
    assert_equal 2, created_patient.laboratories.count
  end

  test 'should create multiple Patients via a transaction' do
    @bundle.entry << patient_entry('Foo', 'Fooson')
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 3, json_response['entry'].length
  end

  test 'should rollback all changes when a Patient is invalid' do
    @bundle.entry << patient_entry('Foo', 'Fooson')
    @bundle.entry.last.resource.address[0].state = 'fooville'
    original_patients = Patient.count
    original_labs = Laboratory.count
    original_cohorts = CommonExposureCohort.count
    post(
      '/fhir/r4',
      params: @bundle.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :unprocessable_entity
    assert_equal original_patients, Patient.count
    assert_equal original_labs, Laboratory.count
    assert_equal original_cohorts, CommonExposureCohort.count
  end
end
