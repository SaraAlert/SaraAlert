# frozen_string_literal: true

require 'test_helper'
require 'rspec/mocks/minitest_integration'
require 'controllers/fhir/r4/api_controller_test'

class ApiControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_vaccines
  end

  def setup_vaccines
    group_name = Vaccine::VACCINE_STANDARDS.keys.sample
    @vaccine_1 = Vaccine.new(
      patient_id: 1,
      group_name: group_name,
      product_name: Vaccine.product_name_options(group_name).sample,
      administration_date: 2.days.ago,
      dose_number: 1,
      notes: 'Foo',
      created_at: 1.days.ago,
      updated_at: 1.days.ago
    )
  end
  #----- show tests -----

  test 'should get Immunization via show' do
    vaccine_id = 3
    get(
      '/fhir/r4/Immunization/' + vaccine_id.to_s,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    assert_equal JSON.parse(Vaccine.find_by_id(vaccine_id).as_fhir.to_json), JSON.parse(response.body)
  end

  test 'should be forbidden via show for inaccessible Immunization' do
    get(
      '/fhir/r4/Immunization/4',
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  #----- create tests -----

  test 'should create Immunization via create' do
    post(
      '/fhir/r4/Immunization',
      params: @vaccine_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :created
    json_response = JSON.parse(response.body)
    id = json_response['id']
    created_vac = Vaccine.find_by(id: id)
    assert_not created_vac.nil?

    # Verify that the created Vaccine matches the original
    %i[patient_id
       group_name
       product_name
       administration_date
       dose_number
       notes].each do |field|
      assert_equal @vaccine_1[field], created_vac[field]
    end

    # Verify that the JSON response matches the original as FHIR
    assert_equal JSON.parse(@vaccine_1.as_fhir.to_json).except('id', 'meta'), json_response.except('id', 'meta')

    histories = History.where(patient: created_vac.patient_id)
    assert_equal(1, histories.count)
    assert_equal 'system-test-everything (API)', histories.first.created_by
    assert_match(/vaccine added.*API/, histories.first.comment)
  end

  test 'SYSTEM FLOW: should be unprocessable entity via Immunization create with invalid Patient reference' do
    @vaccine_1.patient_id = 0
    post(
      '/fhir/r4/Immunization',
      params: @vaccine_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*client application/, errors[0])
  end

  test 'USER FLOW: should be unprocessable entity via Immunization create with invalid Patient reference' do
    @vaccine_1.patient_id = 0
    post(
      '/fhir/r4/Immunization',
      params: @vaccine_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@user_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*API user/, errors[0])
  end

  test 'should be unprocessable entity via Immunization create with validation errors' do
    inv_dose = @vaccine_1.dose_number = '-1'

    immunization_json_str = @vaccine_1.as_fhir.to_json
    immunization_json = JSON.parse(immunization_json_str)
    post(
      '/fhir/r4/Immunization',
      params: immunization_json_str,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    issues = json_response['issue']

    assert_equal 1, issues.length
    dose_number_iss = issues.find { |i| /-1.*Dose Number/.match(i['diagnostics']) }
    assert(FHIRPath.evaluate(dose_number_iss['expression'].first, immunization_json) == inv_dose)
  end

  #----- update tests -----

  test 'should update Immunization via update' do
    @vaccine_1.save
    original_v = @vaccine_1.dup
    @vaccine_1.notes = 'Some new notes'
    put(
      "/fhir/r4/Immunization/#{@vaccine_1.id}",
      params: @vaccine_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    updated_v = Vaccine.find_by_id(@vaccine_1.id)

    # Verify that the updated Vaccine matches the original outside of updated fields
    %i[patient_id
       group_name
       product_name
       administration_date
       dose_number].each do |field|
      assert_equal original_v[field], updated_v[field]
    end

    # Verify that updated fields are updated
    assert_equal 'Some new notes', updated_v.notes

    histories = History.where(patient: updated_v.patient_id)
    assert_equal(1, histories.count)
    assert_equal 'system-test-everything (API)', histories.first.created_by
    assert_match(/Vaccination edited.*API/, histories.first.comment)
  end

  test 'should update Immunization via patch update' do
    @vaccine_1.save
    original_v = @vaccine_1.dup
    patch = [
      { 'op': 'replace', 'path': '/protocolApplied/0/doseNumberString', 'value': 'Unknown' }
    ]
    patch(
      "/fhir/r4/Immunization/#{@vaccine_1.id}",
      params: patch.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/json-patch+json' }
    )
    assert_response :ok
    updated_v = Vaccine.find_by_id(@vaccine_1.id)

    # Verify that the updated Vaccine matches the original outside of updated fields
    %i[patient_id
       group_name
       product_name
       administration_date
       notes].each do |field|
      assert_equal original_v[field], updated_v[field]
    end

    # Verify that updated fields are updated
    assert_equal 'Unknown', updated_v.dose_number
  end

  test 'SYSTEM FLOW: should be unprocessable entity via Immunization update with invalid Patient reference' do
    @vaccine_1.save
    @vaccine_1.patient_id = 0
    put(
      "/fhir/r4/Immunization/#{@vaccine_1.id}",
      params: @vaccine_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*client application/, errors[0])
  end

  test 'USER FLOW: should be unprocessable entity via Immunization update with invalid Patient reference' do
    @vaccine_1.save
    @vaccine_1.patient_id = 0
    put(
      "/fhir/r4/Immunization/#{@vaccine_1.id}",
      params: @vaccine_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@user_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*API user/, errors[0])
  end

  test 'should be unprocessable entity via Immunization update with validation errors' do
    @vaccine_1.save
    inv_dose = @vaccine_1.dose_number = '-1'

    immunization_json_str = @vaccine_1.as_fhir.to_json
    immunization_json = JSON.parse(immunization_json_str)
    put(
      "/fhir/r4/Immunization/#{@vaccine_1.id}",
      params: immunization_json_str,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    issues = json_response['issue']

    assert_equal 1, issues.length
    dose_number_iss = issues.find { |i| /-1.*Dose Number/.match(i['diagnostics']) }
    assert(FHIRPath.evaluate(dose_number_iss['expression'].first, immunization_json) == inv_dose)
  end

  #----- search tests -----

  test 'should find Immunizations for a Patient via search' do
    @vaccine_1.patient_id = 2
    @vaccine_1.save
    patient = Patient.find_by_id(@vaccine_1.patient_id)
    get(
      "/fhir/r4/Immunization?patient=Patient/#{@vaccine_1.patient_id}",
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'Immunization', json_response['entry'].first['resource']['resourceType']
    assert_equal patient.vaccines.length, json_response['total']
    assert_equal JSON.parse(patient.vaccines.first.as_fhir.to_json), json_response['entry'].first['resource']
  end

  test 'should find no Immunizations for an invalid Patient via search' do
    get(
      '/fhir/r4/Immunization?patient=Patient/blah',
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end
end
