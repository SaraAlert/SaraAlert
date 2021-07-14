# frozen_string_literal: true

require 'api_controller_test_case'

class ApiControllerTest < ApiControllerTestCase
  setup do
    setup_system_applications
    setup_system_tokens
    setup_user_applications
    setup_labs
    setup_logger
  end

  def setup_labs
    patient_1 = create(:patient, creator: User.find_by_id(@system_everything_app.user_id))
    @lab_1 = create(
      :laboratory,
      lab_type: Laboratory::LAB_TYPE_TO_CODE.keys.sample,
      result: Laboratory::RESULT_TO_CODE.keys.sample,
      specimen_collection: 2.days.ago,
      report: 1.day.ago,
      patient: patient_1
    )
  end
  #----- show tests -----

  test 'should get Observation via show' do
    get(
      "/fhir/r4/Observation/#{@lab_1.id}",
      headers: { Authorization: "Bearer #{@system_observation_token_r.token}", Accept: 'application/fhir+json' }
    )
    assert_response :ok
    assert_equal JSON.parse(@lab_1.as_fhir.to_json), JSON.parse(response.body)
  end

  #----- create tests -----

  test 'should create Observation via create' do
    post(
      '/fhir/r4/Observation',
      params: @lab_1.as_fhir.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :created
    json_response = JSON.parse(response.body)
    id = json_response['id']
    created_lab = Laboratory.find_by(id: id)
    assert_not created_lab.nil?

    # Verify that the created Vaccine matches the original
    %i[patient_id
       lab_type
       specimen_collection
       report
       result].each do |field|
      assert_equal @lab_1[field], created_lab[field]
    end

    # Verify that the JSON response matches the original as FHIR
    assert_equal JSON.parse(@lab_1.as_fhir.to_json).except('id', 'meta'), json_response.except('id', 'meta')

    histories = History.where(patient: created_lab.patient_id)
    assert_equal(1, histories.count)
    assert_equal 'system-test-everything (API)', histories.first.created_by
    assert_match(/lab result added.*API/, histories.first.comment)
  end

  test 'SYSTEM FLOW: should be unprocessable entity via Observation create with invalid Patient reference' do
    @lab_1.patient_id = 0
    post(
      '/fhir/r4/Observation',
      params: @lab_1.as_fhir.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*client application/, errors[0])
  end

  test 'USER FLOW: should be unprocessable entity via Observation create with invalid Patient reference' do
    @lab_1.patient_id = 0
    post(
      '/fhir/r4/Observation',
      params: @lab_1.as_fhir.to_json,
      headers: { Authorization: "Bearer #{@user_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*API user/, errors[0])
  end

  test 'should be unprocessable entity via Observation create with validation errors' do
    inv_result = { 'system' => 'foo', 'code' => 'foo' }
    lab_1_as_fhir = @lab_1.as_fhir
    lab_1_as_fhir.valueCodeableConcept.coding = [inv_result]
    observation_json_str = lab_1_as_fhir.to_json
    observation_json = JSON.parse(observation_json_str)
    post(
      '/fhir/r4/Observation',
      params: observation_json_str,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    issues = json_response['issue']

    assert_equal 1, issues.length
    result_iss = issues.find { |i| /foo.*Result/.match(i['diagnostics']) }
    assert(FHIRPath.evaluate(result_iss['expression'].first, observation_json) == inv_result)
  end

  #----- update tests -----

  test 'should update Observation via update' do
    original_lab = @lab_1.dup
    new_specimen_collection = @lab_1.specimen_collection - 1.day
    @lab_1.specimen_collection = new_specimen_collection
    put(
      "/fhir/r4/Observation/#{@lab_1.id}",
      params: @lab_1.as_fhir.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok

    # Verify that the updated Lab matches the original outside of updated fields
    %i[patient_id
       lab_type
       report
       result].each do |field|
      assert_equal original_lab[field], @lab_1[field]
    end

    # Verify that updated fields are updated
    assert_equal new_specimen_collection, @lab_1.reload.specimen_collection

    histories = History.where(patient: @lab_1.patient_id)
    assert_equal(1, histories.count)
    assert_equal 'system-test-everything (API)', histories.first.created_by
    assert_match(/Lab result edited.*API/, histories.first.comment)
  end

  test 'should update Observation via patch update' do
    original_lab = @lab_1.dup
    new_specimen_collection = @lab_1.specimen_collection - 1.day
    patch = [
      { op: 'replace', path: '/effectiveDateTime', value: new_specimen_collection.to_s }
    ]
    patch(
      "/fhir/r4/Observation/#{@lab_1.id}",
      params: patch.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/json-patch+json' }
    )
    assert_response :ok

    # Verify that the updated Lab matches the original outside of updated fields
    %i[patient_id
       lab_type
       report
       result].each do |field|
      assert_equal original_lab[field], @lab_1[field]
    end

    # Verify that updated fields are updated
    assert_equal new_specimen_collection, @lab_1.reload.specimen_collection
  end

  test 'SYSTEM FLOW: should be unprocessable entity via Observation update with invalid Patient reference' do
    @lab_1.patient_id = 0
    put(
      "/fhir/r4/Observation/#{@lab_1.id}",
      params: @lab_1.as_fhir.to_json,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*client application/, errors[0])
  end

  test 'USER FLOW: should be unprocessable entity via Observation update with invalid Patient reference' do
    @lab_1.patient_id = 0
    put(
      "/fhir/r4/Observation/#{@lab_1.id}",
      params: @lab_1.as_fhir.to_json,
      headers: { Authorization: "Bearer #{@user_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*API user/, errors[0])
  end

  test 'should be unprocessable entity via Observation update with validation errors' do
    inv_result = { 'system' => 'foo', 'code' => 'foo' }
    lab_1_as_fhir = @lab_1.as_fhir
    lab_1_as_fhir.valueCodeableConcept.coding = [inv_result]
    observation_json_str = lab_1_as_fhir.to_json
    observation_json = JSON.parse(observation_json_str)
    put(
      "/fhir/r4/Observation/#{@lab_1.id}",
      params: observation_json_str,
      headers: { Authorization: "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    issues = json_response['issue']

    assert_equal 1, issues.length
    result_iss = issues.find { |i| /foo.*Result/.match(i['diagnostics']) }
    assert(FHIRPath.evaluate(result_iss['expression'].first, observation_json) == inv_result)
  end

  #----- search tests -----

  test 'should find Observations for a Patient via search' do
    get(
      '/fhir/r4/Observation?subject=Patient/1',
      headers: { Authorization: "Bearer #{@system_observation_token_r.token}", Accept: 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'Observation', json_response['entry'].first['resource']['resourceType']
  end

  test 'should find no Observations for an invalid Patient via search' do
    get(
      '/fhir/r4/Observation?subject=Patient/blah',
      headers: { Authorization: "Bearer #{@system_observation_token_r.token}", Accept: 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end
end
