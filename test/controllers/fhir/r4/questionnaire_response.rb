# frozen_string_literal: true

require 'api_controller_test_case'

class QuestionnaireResponseTest < ApiControllerTestCase
  setup do
    setup_system_applications
    setup_system_tokens
    setup_logger
  end
  #----- show tests -----

  test 'should get QuestionnaireResponse via show' do
    get(
      '/fhir/r4/QuestionnaireResponse/1001',
      headers: { Authorization: "Bearer #{@system_response_token_r.token}", Accept: 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1001, json_response['id']
    assert_equal 'QuestionnaireResponse', json_response['resourceType']
    assert_equal 'Patient/1', json_response['subject']['reference']
    assert_not json_response['item'].find(text: 'fever').first['answer'].first['valueBoolean']
    assert_not json_response['item'].find(text: 'cough').first['answer'].first['valueBoolean']
    assert_not json_response['item'].find(text: 'difficulty-breathing').first['answer'].first['valueBoolean']
  end

  #----- search tests -----

  test 'should find QuestionnaireResponses for a Patient via search' do
    get(
      '/fhir/r4/QuestionnaireResponse?subject=Patient/1',
      headers: { Authorization: "Bearer #{@system_response_token_r.token}", Accept: 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'QuestionnaireResponse', json_response['entry'].first['resource']['resourceType']
  end

  test 'should find no QuestionnaireResponses for an invalid Patient via search' do
    get(
      '/fhir/r4/QuestionnaireResponse?subject=Patient/blah',
      headers: { Authorization: "Bearer #{@system_response_token_r.token}", Accept: 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end
end
