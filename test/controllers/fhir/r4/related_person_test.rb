# frozen_string_literal: true

require 'test_helper'
require 'rspec/mocks/minitest_integration'
require 'controllers/fhir/r4/api_controller_test'

class ApiControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_close_contacts
  end

  def setup_close_contacts
    @close_contact_1 = CloseContact.new(
      patient_id: 1,
      first_name: 'Domingo54',
      last_name: 'Boehm62',
      primary_telephone: '+15555550111',
      email: 'jeremy@example.com',
      contact_attempts: 3,
      last_date_of_exposure: 20.days.ago,
      assigned_user: 8,
      notes: 'Only the educated are free.'
    )
  end

  test 'should create RelatedPerson via create' do
    post(
      '/fhir/r4/RelatedPerson',
      params: @close_contact_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    id = json_response['id']
    created_cc = CloseContact.find_by(id: id)
    assert_not created_cc.nil?

    # Verify that the created Close Contact matches the original
    %i[patient_id
       first_name
       last_name
       primary_telephone
       email
       contact_attempts
       last_date_of_exposure
       assigned_user
       notes].each do |field|
      assert_equal @close_contact_1[field], created_cc[field]
    end

    # Verify that the JSON response matches the original as FHIR
    assert_equal JSON.parse(@close_contact_1.as_fhir.to_json), json_response.except('id')
  end

  test 'SYSTEM FLOW: should be unprocessable entity via create with invalid Patient reference' do
    @close_contact_1.patient_id = 0
    post(
      '/fhir/r4/RelatedPerson',
      params: @close_contact_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*client application/, errors[0])
  end

  test 'USER FLOW: should be unprocessable entity via create with invalid Patient reference' do
    @close_contact_1.patient_id = 0
    post(
      '/fhir/r4/RelatedPerson',
      params: @close_contact_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@user_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*API user/, errors[0])
  end
end
