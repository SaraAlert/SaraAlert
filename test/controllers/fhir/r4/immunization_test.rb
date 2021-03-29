# frozen_string_literal: true

require 'test_helper'
require 'rspec/mocks/minitest_integration'
require 'controllers/fhir/r4/api_controller_test'

class ApiControllerTest < ActionDispatch::IntegrationTest
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
end
