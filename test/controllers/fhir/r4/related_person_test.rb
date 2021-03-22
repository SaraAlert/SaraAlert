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
      notes: 'Only the educated are free.',
      updated_at: 33.days.ago,
      created_at: 33.days.ago
    )
  end
  #----- show tests -----

  test 'should get RelatedPerson via show' do
    get(
      '/fhir/r4/RelatedPerson/1',
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    assert_equal JSON.parse(CloseContact.find_by_id(1).as_fhir.to_json), JSON.parse(response.body)
  end

  test 'should be forbidden via show for inaccessible RelatedPerson' do
    get(
      '/fhir/r4/RelatedPerson/2',
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  #----- create tests -----

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
    assert_equal JSON.parse(@close_contact_1.as_fhir.to_json).except('meta'), json_response.except('id', 'meta')

    histories = History.where(patient: created_cc.patient_id)
    assert_equal(1, histories.count)
    assert_equal 'system-test-everything (API)', histories.first.created_by
    assert_match(/close contact added.*API/, histories.first.comment)
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

  test 'should be unprocessable entity via RelatedPerson create with validation errors' do
    inv_ass_usr = @close_contact_1.assigned_user = 999_999_999
    @close_contact_1.first_name = nil
    @close_contact_1.last_name = nil
    related_person_json_str = @close_contact_1.as_fhir.to_json
    related_person_json = JSON.parse(related_person_json_str)
    post(
      '/fhir/r4/RelatedPerson',
      params: related_person_json_str,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    issues = json_response['issue']

    assert_equal 2, issues.length
    assigned_usr_iss = issues.find { |i| /999999999.*Assigned User/.match(i['diagnostics']) }
    assert(FHIRPath.evaluate(assigned_usr_iss['expression'].first, related_person_json) == inv_ass_usr)
    assert(issues.any? { |i| /At least one.*First Name.*Last Name/.match(i['diagnostics']) })
  end

  #----- update tests -----

  test 'should update RelatedPerson via update' do
    cc = CloseContact.find_by_id(1)
    original_cc = cc.dup
    cc.notes = 'Some new notes'
    cc.first_name = 'FarContact1'
    put(
      '/fhir/r4/RelatedPerson/1',
      params: cc.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    updated_cc = CloseContact.find_by_id(1)

    # Verify that the created Close Contact matches the original outside of updated fields
    %i[patient_id
       last_name
       primary_telephone
       email
       contact_attempts
       last_date_of_exposure
       assigned_user].each do |field|
      assert_equal original_cc[field], updated_cc[field]
    end

    # Verify that updated fields are updated
    assert_equal 'Some new notes', updated_cc.notes
    assert_equal 'FarContact1', updated_cc.first_name

    histories = History.where(patient: updated_cc.patient_id)
    assert_equal(1, histories.count)
    assert_equal 'system-test-everything (API)', histories.first.created_by
    assert_match(/Close contact edited.*API/, histories.first.comment)
  end

  test 'should update RelatedPerson via patch update' do
    cc = CloseContact.find_by_id(1)
    original_cc = cc.dup
    patch = [
      { 'op': 'replace', 'path': '/name/0/given/0', 'value': 'FarContact1' }
    ]
    patch(
      '/fhir/r4/RelatedPerson/1',
      params: patch.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/json-patch+json' }
    )
    assert_response :ok
    updated_cc = CloseContact.find_by_id(1)

    # Verify that the created Close Contact matches the original outside of updated fields
    %i[patient_id
       last_name
       primary_telephone
       email
       contact_attempts
       last_date_of_exposure
       assigned_user
       notes].each do |field|
      assert_equal original_cc[field], updated_cc[field]
    end

    # Verify that updated fields are updated
    assert_equal 'FarContact1', updated_cc.first_name
  end

  test 'SYSTEM FLOW: should be unprocessable entity via update with invalid Patient reference' do
    @close_contact_1.patient_id = 0
    put(
      '/fhir/r4/RelatedPerson/1',
      params: @close_contact_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*client application/, errors[0])
  end

  test 'USER FLOW: should be unprocessable entity via update with invalid Patient reference' do
    @close_contact_1.patient_id = 0
    put(
      '/fhir/r4/RelatedPerson/1',
      params: @close_contact_1.as_fhir.to_json,
      headers: { 'Authorization': "Bearer #{@user_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    assert_equal 1, errors.length
    assert_match(/0.*Patient ID.*API user/, errors[0])
  end

  test 'should be unprocessable entity via RelatedPerson update with validation errors' do
    inv_email = @close_contact_1.email = 'Not an email'
    related_person_json_str = @close_contact_1.as_fhir.to_json
    related_person_json = JSON.parse(related_person_json_str)
    put(
      '/fhir/r4/RelatedPerson/1',
      params: related_person_json_str,
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    issues = json_response['issue']

    assert_equal 1, issues.length
    iss = issues.find { |i| /Not an email.*Email/.match(i['diagnostics']) }
    assert(FHIRPath.evaluate(iss['expression'].first, related_person_json) == inv_email)
  end

  #----- search tests -----

  test 'should find RelatedPersons for a Patient via search' do
    patient_1 = Patient.find_by_id(1)
    get(
      '/fhir/r4/RelatedPerson?patient=Patient/1',
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'RelatedPerson', json_response['entry'].first['resource']['resourceType']
    assert_equal patient_1.close_contacts.length, json_response['total']
    assert_equal JSON.parse(patient_1.close_contacts.first.as_fhir.to_json), json_response['entry'].first['resource']
  end

  test 'should find no RelatedPersons for an invalid Patient via search' do
    get(
      '/fhir/r4/RelatedPerson?patient=Patient/blah',
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end
end
