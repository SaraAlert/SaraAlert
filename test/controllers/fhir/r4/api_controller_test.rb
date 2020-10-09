# frozen_string_literal: true

require 'test_helper'

# rubocop:disable Metrics/ClassLength
class ApiControllerTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    setup_user_applications
    setup_system_applications
    setup_patients
  end

  # Sets up applications registered for user flow
  def setup_user_applications
    @user = User.find_by(email: 'state1_epi@example.com')
    # Make sure API access is enabled for this user.
    @user.update!(api_enabled: true)

    # Create OAuth applications
    @user_patient_read_write_app = Doorkeeper::Application.create(
      name: 'user-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.*'
    )

    @user_patient_read_app = Doorkeeper::Application.create(
      name: 'user-test-patient-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.read'
    )

    @user_patient_write_app = Doorkeeper::Application.create(
      name: 'user-test-patient-w',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.write'
    )

    @user_observation_read_app = Doorkeeper::Application.create(
      name: 'user-test-observation-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Observation.read'
    )

    @user_response_read_app = Doorkeeper::Application.create(
      name: 'user-test-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/QuestionnaireResponse.read'
    )

    @user_patient_rw_observation_r_app = Doorkeeper::Application.create(
      name: 'user-test-patient-rw-observation-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.* user/Observation.read'
    )

    @user_patient_rw_response_r_app = Doorkeeper::Application.create(
      name: 'user-test-patient-rw-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.* user/QuestionnaireResponse.read'
    )

    @user_observation_r_response_r_app = Doorkeeper::Application.create(
      name: 'user-test-observation-r-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/QuestionnaireResponse.read user/Observation.read'
    )

    @user_everything_app = Doorkeeper::Application.create(
      name: 'user-test-everything',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.* user/QuestionnaireResponse.read user/Observation.read'
    )

    # Create access tokens
    @user_patient_token_rw = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_read_write_app,
      scopes: 'user/Patient.*'
    )

    @user_patient_token_r = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_read_app,
      scopes: 'user/Patient.read'
    )

    @user_patient_token_w = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_write_app,
      scopes: 'user/Patient.write'
    )

    @user_observation_token_r = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_observation_read_app,
      scopes: 'user/Observation.read'
    )

    @user_response_token_r = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_response_read_app,
      scopes: 'user/QuestionnaireResponse.read'
    )

    @user_patient_rw_observation_r_token = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_rw_observation_r_app,
      scopes: 'user/Patient.* user/Observation.read'
    )

    @user_patient_rw_response_r_token = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_rw_response_r_app,
      scopes: 'user/Patient.* user/QuestionnaireResponse.read'
    )

    @user_observation_r_response_r_token = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_observation_r_response_r_app,
      scopes: 'user/QuestionnaireResponse.read user/Observation.read'
    )

    @user_everything_token = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_everything_app,
      scopes: 'user/Patient.* user/QuestionnaireResponse.read user/Observation.read'
    )
  end

  # Sets up applications registered for system flow
  def setup_system_applications
    # Create "shadow user" that will is associated with the M2M OAuth apps
    shadow_user = User.create!(
      email: 'test@example.com',
      password: User.rand_gen,
      jurisdiction: Jurisdiction.find_by(id: 2),
      force_password_change: false,
      api_enabled: true
    )
    shadow_user.add_role 'Public Health Enroller'
    shadow_user.save!
    shadow_user.lock_access!

    # Create OAuth applications
    @system_patient_read_write_app = Doorkeeper::Application.create(
      name: 'system-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.*',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_read_app = Doorkeeper::Application.create(
      name: 'system-test-patient-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_write_app = Doorkeeper::Application.create(
      name: 'system-test-patient-w',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.write',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_observation_read_app = Doorkeeper::Application.create(
      name: 'system-test-observation-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_response_read_app = Doorkeeper::Application.create(
      name: 'system-test-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/QuestionnaireResponse.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_rw_observation_r_app = Doorkeeper::Application.create(
      name: 'system-test-patient-rw-observation-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.* system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_rw_response_r_app = Doorkeeper::Application.create(
      name: 'system-test-patient-rw-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.* system/QuestionnaireResponse.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_observation_r_response_r_app = Doorkeeper::Application.create(
      name: 'system-test-observation-r-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/QuestionnaireResponse.read system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_everything_app = Doorkeeper::Application.create(
      name: 'system-test-everything',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.* system/QuestionnaireResponse.read system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    # Create access tokens
    @system_patient_token_rw = Doorkeeper::AccessToken.create(
      application: @system_patient_read_write_app,
      scopes: 'system/Patient.*'
    )
    @system_patient_token_r = Doorkeeper::AccessToken.create(
      application: @system_patient_read_app,
      scopes: 'system/Patient.read'
    )
    @system_patient_token_w = Doorkeeper::AccessToken.create(
      application: @system_patient_write_app,
      scopes: 'system/Patient.write'
    )
    @system_observation_token_r = Doorkeeper::AccessToken.create(
      application: @system_observation_read_app,
      scopes: 'system/Observation.read'
    )
    @system_response_token_r = Doorkeeper::AccessToken.create(
      application: @system_response_read_app,
      scopes: 'system/QuestionnaireResponse.read'
    )
    @system_patient_rw_observation_r_token = Doorkeeper::AccessToken.create(
      application: @system_patient_rw_observation_r_app,
      scopes: 'system/Patient.* system/Observation.read'
    )
    @system_patient_rw_response_r_token = Doorkeeper::AccessToken.create(
      application: @system_patient_rw_response_r_app,
      scopes: 'system/Patient.* system/QuestionnaireResponse.read'
    )
    @system_observation_r_response_r_token = Doorkeeper::AccessToken.create(
      application: @system_observation_r_response_r_app,
      scopes: 'system/QuestionnaireResponse.read system/Observation.read'
    )
    @system_everything_token = Doorkeeper::AccessToken.create(
      application: @system_everything_app,
      scopes: 'system/Patient.* system/QuestionnaireResponse.read system/Observation.read'
    )
  end

  # Sets up FHIR patients used for testing
  def setup_patients
    @patient_1 = Patient.find_by(id: 1).as_fhir

    # Update Patient 2 before created FHIR resource from it
    Patient.find_by(id: 2).update!(
      preferred_contact_method: 'SMS Texted Weblink',
      preferred_contact_time: 'Afternoon',
      last_date_of_exposure: 4.days.ago,
      symptom_onset: 3.days.ago,
      isolation: true,
      primary_telephone: '+15555559999'
    )
    @patient_2 = Patient.find_by(id: 2).as_fhir

    # Update Patient 2 number to guarantee unique phone number
    Patient.find_by(id: 2).update!(
      primary_telephone: '+15555559998'
    )
  end

  test 'GENERAL: should be unauthorized via show' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
  end

  #----- system flow tests -----

  test 'SYSTEM FLOW: should group Patients in households with matching phone numbers' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    # Should be a dependent in the same household as patient with ID 1, who is now the HoH
    assert_equal 1, Patient.find_by(id: json_response['id']).responder_id
  end

  test 'SYSTEM FLOW: should group Patients in households with matching emails' do
    Patient.find_by(id: 1).update!(preferred_contact_method: 'E-mailed Web Link')
    @patient_1 = Patient.find_by(id: 1).as_fhir
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    # Should be a dependent in the same household as patient with ID 1, who is now the HoH
    assert_equal 1, Patient.find_by(id: json_response['id']).responder_id
  end

  test 'SYSTEM FLOW: should make Patient a self reporter if no matching number or email' do
    post(
      '/fhir/r4/Patient',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    # Should be their own reporter since they have a unique phone number and email
    assert_equal json_response['id'], Patient.find_by(id: json_response['id']).responder_id
  end

  test 'SYSTEM FLOW: should not be able to create Patient resource with Patient read scope' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to create Patient resource with Observation scope' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to create Patient resource with QuestionnaireResponse scope' do
    post(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to update Patient resource with Patient read scope' do
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to update Patient resource with Observation scope' do
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to update Patient resource with QuestionnaireResponse scope' do
    put(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to read Patient resource with Patient write only scope' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to read Patient resource with Observation scope' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to read Patient resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to search Patient resource with Patient write only scope' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to search Patient resource with Observation scope' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to search Patient resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to read Observation resource with Patient scope' do
    get(
      '/fhir/r4/Observation/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to read Observation resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Observation/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to read QuestionnaireResponse resource with Patient scope' do
    get(
      '/fhir/r4/QuestionnaireResponse/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to read QuestionnaireResponse resource with Observation scope' do
    get(
      '/fhir/r4/QuestionnaireResponse/1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to get everything with only Patient write only scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to get everything with only Patient read only scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to get everything with only Patient read and write scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to get everything with only Observation scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to get everything with only QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to get everything with only Patient read and write scope and Observation scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_rw_observation_r_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to get everything with only Patient read and write scope and QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_rw_response_r_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should not be able to get everything with only Observation scope and QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_observation_r_response_r_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: patients within exact jurisdiction should be accessable' do
    # Same jurisdiction
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
  end

  test 'SYSTEM FLOW: patients within subjurisdictions should be accessable' do
    # Update jurisdiction to be subjurisdiction
    Patient.find_by(id: 1).update!(jurisdiction_id: 4)
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
  end

  test 'SYSTEM FLOW: patients outside of jurisdiction should NOT be accessable' do
    # Update jurisdiction to be out of scope
    Patient.find_by(id: 1).update!(jurisdiction_id: 1)
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should be 403 forbidden if no resource owner and jurisdiction_id is nil' do
    @system_patient_read_write_app.update!(jurisdiction_id: nil)
    @system_patient_token_rw = Doorkeeper::AccessToken.create(application: @system_patient_read_write_app, scopes: 'system/*.read system/*.write')
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should be 403 forbidden if no resource owner and jurisdiction_id is not a valid id' do
    @system_patient_read_write_app.update!(jurisdiction_id: 100)
    @system_patient_token_rw = Doorkeeper::AccessToken.create(application: @system_patient_read_write_app, scopes: 'system/*.read system/*.write')
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should be 406 when bad accept header via show' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'foo/bar' }
    )
    assert_response :not_acceptable
  end

  test 'SYSTEM FLOW: should get patient via show' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert_equal 'Telephone call', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' }.first['valueString']
    assert_equal 'Morning', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' }.first['valueString']
    assert_equal 45.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'last-exposure-date' }.first['valueDate']
    assert_equal 5.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert_not json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
  end

  test 'SYSTEM FLOW: should get observation via show' do
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

  test 'SYSTEM FLOW: should get QuestionnaireResponse via show' do
    get(
      '/fhir/r4/QuestionnaireResponse/1001',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
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

  test 'SYSTEM FLOW: should be 404 via show when requesting unsupported resource' do
    get(
      '/fhir/r4/FooBar/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'SYSTEM FLOW: should be forbidden via show' do
    get(
      '/fhir/r4/Patient/9',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should be unauthorized via create' do
    post '/fhir/r4/Patient'
    assert_response :unauthorized
  end

  test 'SYSTEM FLOW: should create Patient via create' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    id = json_response['id']
    p = Patient.find_by(id: id)
    assert_not p.nil?
    h = History.where(patient_id: id)
    assert_not h.first.nil?
    assert_equal 1, h.count
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert response.headers['Location'].ends_with?(json_response['id'].to_s)
  end

  test 'SYSTEM FLOW: should calculate Patient age via create' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :created
    json_response = JSON.parse(response.body)
    patient = Patient.find(json_response['id'])
    assert_equal 25, patient.age
  end

  test 'SYSTEM FLOW: should be 415 when bad content type header via create' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'foo/bar' }
    )
    assert_response :unsupported_media_type
  end

  test 'SYSTEM FLOW: should be bad request via create' do
    post(
      '/fhir/r4/Patient',
      params: { foo: 'bar' }.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
  end

  test 'SYSTEM FLOW: should be unauthorized via update' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
  end

  test 'SYSTEM FLOW: should update Patient via update' do
    put(
      '/fhir/r4/Patient/1',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    p = Patient.find_by(id: 1)
    assert_not p.nil?
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 'Kirlin44', json_response['name'].first['family']
    assert_equal 'SMS Texted Weblink', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' }.first['valueString']
    assert_equal 'Afternoon', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' }.first['valueString']
    assert_equal 4.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'last-exposure-date' }.first['valueDate']
    assert_equal 3.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
  end

  test 'SYSTEM FLOW: should be bad request via update due to bad fhir' do
    put(
      '/fhir/r4/Patient/1',
      params: { foo: 'bar' }.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
  end

  test 'SYSTEM FLOW: should be bad request via update due to unsupported resource' do
    put(
      '/fhir/r4/FooBar/9',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'SYSTEM FLOW: should be forbidden via update' do
    put(
      '/fhir/r4/Patient/9',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should be unauthorized via search' do
    get '/fhir/r4/Patient?family=Kirlin44'
    assert_response :unauthorized
  end

  test 'SYSTEM FLOW: should be unauthorized via search write only' do
    get(
      '/fhir/r4/Patient?family=Kirlin44',
      headers: { 'Authorization': "Bearer #{@system_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should find Observations for a Patient via search' do
    get(
      '/fhir/r4/Observation?subject=Patient/1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'Observation', json_response['entry'].first['resource']['resourceType']
  end

  test 'SYSTEM FLOW: should find QuestionnaireResponses for a Patient via search' do
    get(
      '/fhir/r4/QuestionnaireResponse?subject=Patient/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'QuestionnaireResponse', json_response['entry'].first['resource']['resourceType']
  end

  test 'SYSTEM FLOW: should find no Observations for an invalid Patient via search' do
    get(
      '/fhir/r4/Observation?subject=Patient/blah',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'SYSTEM FLOW: should find no QuestionnaireResponses for an invalid Patient via search' do
    get(
      '/fhir/r4/QuestionnaireResponse?subject=Patient/blah',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'SYSTEM FLOW: should find Patient via search by _id' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'SYSTEM FLOW: should find Patient via search on existing family' do
    get(
      '/fhir/r4/Patient?family=Kirlin44',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'SYSTEM FLOW: should find no Patients via search on non-existing family' do
    get(
      '/fhir/r4/Patient?family=foo',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'SYSTEM FLOW: should find Patient via search on given' do
    get(
      '/fhir/r4/Patient?given=Chris32',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'SYSTEM FLOW: should find Patient via search on telecom' do
    get(
      '/fhir/r4/Patient?telecom=5555550111',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'SYSTEM FLOW: should find Patient via search on email' do
    get(
      '/fhir/r4/Patient?email=grazyna%40example.com',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'SYSTEM FLOW: should get Bundle via search without params' do
    get(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    json_response['entry'].each do |entry|
      assert(entry['fullUrl'].include?('Patient') ||
              entry['fullUrl'].include?('Observation') ||
              entry['fullUrl'].include?('QuestionnaireResponse'))
    end
  end

  test 'SYSTEM FLOW: should be 404 via search when requesting unsupported resource' do
    get(
      '/fhir/r4/FooBar?email=grazyna%40example.com',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'SYSTEM FLOW: should be unauthorized via all' do
    get '/fhir/r4/Patient/1/$everything'
    assert_response :unauthorized
  end

  test 'SYSTEM FLOW: should get Bundle via all' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 5, json_response['total']
    assert_equal 1, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Patient' }.count
    assert_equal 2, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'QuestionnaireResponse' }.count
    assert_equal 2, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Observation' }.count
    assert_equal 'Patient/1', json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Observation' }.first['resource']['subject']['reference']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'SYSTEM FLOW: should get patients with default count via search' do
    get(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'http://www.example.com/fhir/r4/Patient?page=2', json_response['link'][0]['url']
  end

  test 'SYSTEM FLOW: should get patients with count as 100 via search' do
    get(
      '/fhir/r4/Patient?_count=100',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end

  test 'SYSTEM FLOW: should only get summary with count as 0 via search' do
    get(
      '/fhir/r4/Patient?_count=0',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end

  test 'SYSTEM FLOW: should get CapabilityStatement unauthorized via capability_statement' do
    get(
      '/fhir/r4/metadata',
      headers: { 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end

  test 'SYSTEM FLOW: should get CapabilityStatement authorized via capability_statement' do
    get(
      '/fhir/r4/metadata',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end

  # ----- end system flow tests -----

  #----- user flow tests -----

  test 'USER FLOW: should group Patients in households with matching phone numbers' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    # Should be a dependent in the same household as patient with ID 1, who is now the HoH
    assert_equal 1, Patient.find_by(id: json_response['id']).responder_id
  end

  test 'USER FLOW: should group Patients in households with matching emails' do
    Patient.find_by(id: 1).update!(preferred_contact_method: 'E-mailed Web Link')
    @patient_1 = Patient.find_by(id: 1).as_fhir
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    # Should be a dependent in the same household as patient with ID 1, who is now the HoH
    assert_equal 1, Patient.find_by(id: json_response['id']).responder_id
  end

  test 'USER FLOW: should make Patient a self reporter if no matching number or email' do
    post(
      '/fhir/r4/Patient',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    # Should be their own reporter since they have a unique phone number and email
    assert_equal json_response['id'], Patient.find_by(id: json_response['id']).responder_id
  end

  test 'USER FLOW: should not be able to create Patient resource with Patient read scope' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to create Patient resource with Observation scope' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to create Patient resource with QuestionnaireResponse scope' do
    post(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@user_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to update Patient resource with Patient read scope' do
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to update Patient resource with Observation scope' do
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to update Patient resource with QuestionnaireResponse scope' do
    put(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to read Patient resource with Patient write only scope' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to read Patient resource with Observation scope' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to read Patient resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to search Patient resource with Patient write only scope' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to search Patient resource with Observation scope' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@user_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to search Patient resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@user_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to read Observation resource with Patient scope' do
    get(
      '/fhir/r4/Observation/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to read Observation resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Observation/1',
      headers: { 'Authorization': "Bearer #{@user_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to read QuestionnaireResponse resource with Patient scope' do
    get(
      '/fhir/r4/QuestionnaireResponse/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to read QuestionnaireResponse resource with Observation scope' do
    get(
      '/fhir/r4/QuestionnaireResponse/1',
      headers: { 'Authorization': "Bearer #{@user_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to get everything with only Patient write only scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@user_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to get everything with only Patient read only scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@user_patient_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to get everything with only Patient read and write scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to get everything with only Observation scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@user_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to get everything with only QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@user_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to get everything with only Patient read and write scope and Observation scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@user_patient_rw_observation_r_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to get everything with only Patient read and write scope and QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@user_patient_rw_response_r_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should not be able to get everything with only Observation scope and QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@user_observation_r_response_r_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  # ----- end user scope tests -----

  test 'USER FLOW: analysts should not have any access to patients' do
    @user = User.find_by(email: 'analyst_all@example.com')
    @user.update!(api_enabled: true)
    @user_patient_token_rw = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_read_write_app,
      scopes: 'user/Patient.*'
    )
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: enrollers should only have access to enrolled patients' do
    # Created patient should be okay
    @user = User.find_by(email: 'state1_enroller@example.com')
    @user.update!(api_enabled: true, jurisdiction_id: 2)
    @user_patient_token_rw = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_read_write_app,
      scopes: 'user/Patient.*'
    )
    Patient.find_by(id: 1).update!(creator_id: @user[:id])

    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']

    # Not created patient should be forbidden okay
    get(
      '/fhir/r4/Patient/2',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: epis should have access to all patients within jurisdiction' do
    @user = User.find_by(email: 'state1_epi@example.com')
    @user.update!(api_enabled: true, jurisdiction_id: 2)
    @user_patient_token_rw = Doorkeeper::AccessToken.create(resource_owner_id: @user.id, application: @user_patient_read_write_app, scopes: 'user/Patient.*')

    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']

    get(
      '/fhir/r4/Patient/2',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response['id']
  end

  test 'USER FLOW: epi enrollers should have access to all patients within jurisdiction' do
    @user = User.find_by(email: 'state1_epi_enroller@example.com')
    @user.update!(api_enabled: true, jurisdiction_id: 2)
    @user_patient_token_rw = Doorkeeper::AccessToken.create(resource_owner_id: @user.id, application: @user_patient_read_write_app, scopes: 'user/Patient.*')

    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']

    get(
      '/fhir/r4/Patient/2',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response['id']
  end

  test 'USER FLOW: should be 403 forbidden when user does not have api access enabled' do
    @user.update!(api_enabled: false)
    @user_patient_token_rw = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_read_write_app,
      scopes: 'user/*.read user/*.write'
    )
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should be 406 when bad accept header via show' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'foo/bar' }
    )
    assert_response :not_acceptable
  end

  test 'USER FLOW: should be unauthorized via show write only' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should get patient via show' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert_equal 'Telephone call', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' }.first['valueString']
    assert_equal 'Morning', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' }.first['valueString']
    assert_equal 45.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'last-exposure-date' }.first['valueDate']
    assert_equal 5.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert_not json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
  end

  test 'USER FLOW: should get observation via show' do
    get(
      '/fhir/r4/Observation/1001',
      headers: { 'Authorization': "Bearer #{@user_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1001, json_response['id']
    assert_equal 'Observation', json_response['resourceType']
    assert_equal 'Patient/1', json_response['subject']['reference']
    assert_equal 'positive', json_response['valueString']
  end

  test 'USER FLOW: should get QuestionnaireResponse via show' do
    get(
      '/fhir/r4/QuestionnaireResponse/1001',
      headers: { 'Authorization': "Bearer #{@user_response_token_r.token}", 'Accept': 'application/fhir+json' }
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

  test 'USER FLOW: should be 404 via show when requesting unsupported resource' do
    get(
      '/fhir/r4/FooBar/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'USER FLOW: should be forbidden via show' do
    get(
      '/fhir/r4/Patient/9',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should be unauthorized via create' do
    post '/fhir/r4/Patient'
    assert_response :unauthorized
  end

  test 'USER FLOW: should be unauthorized via create read only' do
    post '/fhir/r4/Patient', params: @patient_1.to_json,
                             headers: { 'Authorization': "Bearer #{@user_patient_token_r.token}" }
    assert_response :forbidden
  end

  test 'USER FLOW: should create Patient via create' do
    post(
      '/fhir/r4/Patient', params: @patient_1.to_json,
                          headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    id = json_response['id']
    p = Patient.find_by(id: id)
    assert_not p.nil?
    h = History.where(patient_id: id)
    assert_not h.first.nil?
    assert_equal 1, h.count
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert response.headers['Location'].ends_with?(json_response['id'].to_s)
  end

  test 'USER FLOW: should calculate Patient age via create' do
    post(
      '/fhir/r4/Patient', params: @patient_1.to_json,
                          headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    patient = Patient.find(json_response['id'])
    assert_equal 25, patient.age
  end

  test 'USER FLOW: should be 415 when bad content type header via create' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'foo/bar' }
    )
    assert_response :unsupported_media_type
  end

  test 'USER FLOW: should be bad request via create' do
    post(
      '/fhir/r4/Patient',
      params: { foo: 'bar' }.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
  end

  test 'USER FLOW: should be unauthorized via update' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
  end

  test 'USER FLOW: should be unauthorized via update read only' do
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_r.token}" }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should update Patient via update' do
    put(
      '/fhir/r4/Patient/1',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    p = Patient.find_by(id: 1)
    assert_not p.nil?
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 'Kirlin44', json_response['name'].first['family']
    assert_equal 'SMS Texted Weblink', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' }.first['valueString']
    assert_equal 'Afternoon', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' }.first['valueString']
    assert_equal 4.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'last-exposure-date' }.first['valueDate']
    assert_equal 3.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
  end

  test 'USER FLOW: should be bad request via update due to bad fhir' do
    put(
      '/fhir/r4/Patient/1',
      params: { foo: 'bar' }.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
  end

  test 'USER FLOW: should be 404 not found via update due to unsupported resource' do
    put(
      '/fhir/r4/FooBar/9',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'USER FLOW: should be forbidden via update' do
    put(
      '/fhir/r4/Patient/9',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should be unauthorized via search' do
    get '/fhir/r4/Patient?family=Kirlin44'
    assert_response :unauthorized
  end

  test 'USER FLOW: should be unauthorized via search write only' do
    get(
      '/fhir/r4/Patient?family=Kirlin44',
      headers: { 'Authorization': "Bearer #{@user_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: should find Observations for a Patient via search' do
    get(
      '/fhir/r4/Observation?subject=Patient/1',
      headers: { 'Authorization': "Bearer #{@user_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'Observation', json_response['entry'].first['resource']['resourceType']
  end

  test 'USER FLOW: should find QuestionnaireResponses for a Patient via search' do
    get(
      '/fhir/r4/QuestionnaireResponse?subject=Patient/1',
      headers: { 'Authorization': "Bearer #{@user_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'QuestionnaireResponse', json_response['entry'].first['resource']['resourceType']
  end

  test 'USER FLOW: should find no Observations for an invalid Patient via search' do
    get(
      '/fhir/r4/Observation?subject=Patient/blah',
      headers: { 'Authorization': "Bearer #{@user_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'USER FLOW: should find no QuestionnaireResponses for an invalid Patient via search' do
    get(
      '/fhir/r4/QuestionnaireResponse?subject=Patient/blah',
      headers: { 'Authorization': "Bearer #{@user_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'USER FLOW: should find Patient via search by _id' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'USER FLOW: should find Patient via search on existing family' do
    get(
      '/fhir/r4/Patient?family=Kirlin44',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'USER FLOW: should find no Patients via search on non-existing family' do
    get(
      '/fhir/r4/Patient?family=foo',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'USER FLOW: should find Patient via search on given' do
    get(
      '/fhir/r4/Patient?given=Chris32',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'USER FLOW: should find Patient via search on telecom' do
    get(
      '/fhir/r4/Patient?telecom=15555550111',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'USER FLOW: should find Patient via search on email' do
    get(
      '/fhir/r4/Patient?email=grazyna%40example.com',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'USER FLOW: should get Bundle via search without params' do
    get(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    json_response['entry'].each do |entry|
      assert(entry['fullUrl'].include?('Patient') ||
              entry['fullUrl'].include?('Observation') ||
              entry['fullUrl'].include?('QuestionnaireResponse'))
    end
  end

  test 'USER FLOW: should be 404 via search when requesting unsupported resource' do
    get(
      '/fhir/r4/FooBar?email=grazyna%40example.com',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'USER FLOW: should be unauthorized via all' do
    get '/fhir/r4/Patient/1/$everything'
    assert_response :unauthorized
  end

  test 'USER FLOW: should get Bundle via all' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@user_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 5, json_response['total']
    assert_equal 1, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Patient' }.count
    assert_equal 2, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'QuestionnaireResponse' }.count
    assert_equal 2, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Observation' }.count
    assert_equal 'Patient/1', json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Observation' }.first['resource']['subject']['reference']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'USER FLOW: should get patients with default count via search' do
    get(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'http://www.example.com/fhir/r4/Patient?page=2', json_response['link'][0]['url']
  end

  test 'USER FLOW: should get patients with count as 100 via search' do
    get(
      '/fhir/r4/Patient?_count=100',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end

  test 'USER FLOW: should only get summary with count as 0 via search' do
    get(
      '/fhir/r4/Patient?_count=0',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end

  test 'USER FLOW: should get CapabilityStatement unauthorized via capability_statement' do
    get(
      '/fhir/r4/metadata',
      headers: { 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end

  test 'USER FLOW: should get CapabilityStatement authorized via capability_statement' do
    get(
      '/fhir/r4/metadata',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end
  # ----- end user flow tests -----
end
# rubocop:enable Metrics/ClassLength
