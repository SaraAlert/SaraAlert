# frozen_string_literal: true

require 'test_helper'
require 'rspec/mocks/minitest_integration'
require 'controllers/fhir/r4/api_controller_test'

class ApiControllerTest < ActionDispatch::IntegrationTest
  #----- show tests -----

  test 'should get Observation via show' do
    get(
      '/fhir/r4/Observation/1001',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1001, json_response['id']
    assert_equal 'Observation', json_response['resourceType']
    assert_equal 'Patient/1', json_response['subject']['reference']
    assert_equal 'positive', json_response['valueString']
  end

  #----- search tests -----

  test 'should find Observations for a Patient via search' do
    get(
      '/fhir/r4/Observation?subject=Patient/1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'Observation', json_response['entry'].first['resource']['resourceType']
  end

  test 'should find no Observations for an invalid Patient via search' do
    get(
      '/fhir/r4/Observation?subject=Patient/blah',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end
end
