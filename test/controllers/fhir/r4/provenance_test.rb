# frozen_string_literal: true

require 'test_helper'
require 'rspec/mocks/minitest_integration'
require 'controllers/fhir/r4/api_controller_test'

class ApiControllerTest < ActionDispatch::IntegrationTest
  #----- show tests -----

  test 'should get Provenance via show' do
    history_id = 2006
    get(
      '/fhir/r4/Provenance/' + history_id.to_s,
      headers: { Authorization: "Bearer #{@system_provenance_token_r.token}", Accept: 'application/fhir+json' }
    )
    assert_response :ok
    assert_equal JSON.parse(History.find_by(id: history_id).as_fhir.to_json), JSON.parse(response.body)
  end

  test 'should be forbidden via show for inaccessible Provenance' do
    get(
      '/fhir/r4/Provenance/4',
      headers: { Authorization: "Bearer #{@system_everything_token.token}", Accept: 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  #----- search tests -----

  test 'should find Provenances for a Patient via search' do
    patient = Patient.find_by(id: 6)
    get(
      '/fhir/r4/Provenance?patient=Patient/6',
      headers: { Authorization: "Bearer #{@system_everything_token.token}", Accept: 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'Provenance', json_response['entry'].first['resource']['resourceType']
    assert_equal patient.histories.length, json_response['total']
    assert_equal JSON.parse(patient.histories.first.as_fhir.to_json), json_response['entry'].first['resource']
  end

  test 'should find no Provenances for an invalid Patient via search' do
    get(
      '/fhir/r4/Provenance?patient=Patient/blah',
      headers: { Authorization: "Bearer #{@system_everything_token.token}", Accept: 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end
end
