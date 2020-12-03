# frozen_string_literal: true

require 'test_helper'
require 'rspec/mocks/minitest_integration'

# rubocop:disable Metrics/ClassLength
class ApiControllerTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    setup_user_applications
    setup_system_applications
    setup_patients
    # Suppress logging calls originating from:
    # https://github.com/fhir-crucible/fhir_models/blob/v4.1.0/lib/fhir_models/bootstrap/json.rb
    logger_double = double('logger_double', debug: nil, info: nil, warning: nil, error: nil)
    FHIR.logger = logger_double
  end

  # Sets up applications registered for user flow
  def setup_user_applications
    @user = User.find_by(email: 'state1_epi@example.com')
    # Make sure API access is enabled for this user.
    @user.update!(api_enabled: true)

    # Create OAuth applications
    @user_patient_read_write_app = OauthApplication.create(
      name: 'user-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.*'
    )

    # Create access tokens
    @user_patient_token_rw = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_read_write_app,
      scopes: 'user/Patient.*'
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
      api_enabled: true,
      role: 'public_health_enroller',
      is_api_proxy: true
    )
    shadow_user.lock_access!

    # Create OAuth applications
    @system_patient_read_write_app = OauthApplication.create(
      name: 'system-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.*',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_read_app = OauthApplication.create(
      name: 'system-test-patient-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_write_app = OauthApplication.create(
      name: 'system-test-patient-w',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.write',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_observation_read_app = OauthApplication.create(
      name: 'system-test-observation-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_response_read_app = OauthApplication.create(
      name: 'system-test-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/QuestionnaireResponse.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_rw_observation_r_app = OauthApplication.create(
      name: 'system-test-patient-rw-observation-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.* system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_rw_response_r_app = OauthApplication.create(
      name: 'system-test-patient-rw-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.* system/QuestionnaireResponse.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_observation_r_response_r_app = OauthApplication.create(
      name: 'system-test-observation-r-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/QuestionnaireResponse.read system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_everything_app = OauthApplication.create(
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
    Patient.find_by(id: 1).update!(
      assigned_user: '1234',
      exposure_notes: 'exposure notes',
      travel_related_notes: 'travel notes',
      additional_planned_travel_related_notes: 'additional travel notes'
    )
    @patient_1 = Patient.find_by(id: 1).as_fhir

    # Update Patient 2 before created FHIR resource from it
    Patient.find_by(id: 2).update!(
      preferred_contact_method: 'SMS Texted Weblink',
      preferred_contact_time: 'Afternoon',
      last_date_of_exposure: 4.days.ago,
      symptom_onset: 3.days.ago,
      isolation: true,
      primary_telephone: '+15555559999',
      jurisdiction_id: 4,
      monitoring_plan: 'Daily active monitoring',
      assigned_user: '2345',
      additional_planned_travel_start_date: 5.days.from_now,
      port_of_origin: 'Tortuga',
      date_of_departure: 2.days.ago,
      flight_or_vessel_number: 'XYZ123',
      flight_or_vessel_carrier: 'FunAirlines',
      date_of_arrival: 2.days.from_now,
      exposure_notes: 'exposure notes',
      travel_related_notes: 'travel related notes',
      additional_planned_travel_related_notes: 'additional travel related notes',
      primary_telephone_type: 'Plain Cell',
      secondary_telephone_type: 'Landline'
    )
    @patient_2 = Patient.find_by(id: 2).as_fhir

    # Update Patient 2 number to guarantee unique phone number
    Patient.find_by(id: 2).update!(
      primary_telephone: '+15555559998'
    )
  end

  #----- scope tests -----

  test 'should not be able to create Patient resource with Patient read scope' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to create Patient resource with Observation scope' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to create Patient resource with QuestionnaireResponse scope' do
    post(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to update Patient resource with Patient read scope' do
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to update Patient resource with Observation scope' do
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to update Patient resource with QuestionnaireResponse scope' do
    put(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read Patient resource with Patient write only scope' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read Patient resource with Observation scope' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read Patient resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to search Patient resource with Patient write only scope' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to search Patient resource with Observation scope' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to search Patient resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read Observation resource with Patient scope' do
    get(
      '/fhir/r4/Observation/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read Observation resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Observation/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read QuestionnaireResponse resource with Patient scope' do
    get(
      '/fhir/r4/QuestionnaireResponse/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read QuestionnaireResponse resource with Observation scope' do
    get(
      '/fhir/r4/QuestionnaireResponse/1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to get everything with only Patient write only scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to get everything with only Patient read only scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to get everything with only Patient read and write scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to get everything with only Observation scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to get everything with only QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to get everything with only Patient read and write scope and Observation scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_rw_observation_r_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to get everything with only Patient read and write scope and QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_patient_rw_response_r_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to get everything with only Observation scope and QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_observation_r_response_r_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  #----- show tests -----

  test 'should be unauthorized via show' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
  end

  test 'should be 403 forbidden if no resource owner and jurisdiction_id is nil' do
    @system_patient_read_write_app.update!(jurisdiction_id: nil)
    @system_patient_token_rw = Doorkeeper::AccessToken.create(application: @system_patient_read_write_app, scopes: 'system/*.read system/*.write')
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should be 403 forbidden if no resource owner and jurisdiction_id is not a valid id' do
    @system_patient_read_write_app.update!(jurisdiction_id: 100)
    @system_patient_token_rw = Doorkeeper::AccessToken.create(application: @system_patient_read_write_app, scopes: 'system/*.read system/*.write')
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should be 406 when bad accept header via show' do
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'foo/bar' }
    )
    assert_response :not_acceptable
  end

  test 'should get patient via show' do
    patient_id = 1
    patient = Patient.find_by(id: patient_id)
    resource_path = "/fhir/r4/Patient/#{patient_id}"
    get(
      resource_path,
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
    assert_equal 45.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'last-date-of-exposure' }.first['valueDate']
    assert_equal 5.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert_not json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
    assert_equal resource_path, json_response['contained'].first['target'].first['reference']
    assert_equal Patient.find_by(id: patient_id).creator_id, json_response['contained'].first['agent'].first['who']['identifier']['value']
    assert_equal Patient.find_by(id: patient_id).creator.email, json_response['contained'].first['agent'].first['who']['display']
    assert_equal patient.primary_telephone_type, fhir_ext_str(json_response['telecom'].first, 'phone-type')
    assert_equal patient.secondary_telephone_type, fhir_ext_str(json_response['telecom'].second, 'phone-type')
    assert_equal patient.monitoring_plan, fhir_ext_str(json_response, 'monitoring-plan')
    assert_equal patient.assigned_user, fhir_ext_pos_int(json_response, 'assigned-user')
    assert_equal patient.additional_planned_travel_start_date.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'additional-planned-travel-start-date')
    assert_equal patient.port_of_origin, fhir_ext_str(json_response, 'port-of-origin')
    assert_equal patient.date_of_departure.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-departure')
    assert_equal patient.flight_or_vessel_number, fhir_ext_str(json_response, 'flight-or-vessel-number')
    assert_equal patient.flight_or_vessel_carrier, fhir_ext_str(json_response, 'flight-or-vessel-carrier')
    assert_equal patient.date_of_arrival.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-arrival')
    assert_equal patient.exposure_notes, fhir_ext_str(json_response, 'exposure-notes')
    assert_equal patient.travel_related_notes, fhir_ext_str(json_response, 'travel-related-notes')
    assert_equal patient.additional_planned_travel_related_notes, fhir_ext_str(json_response, 'additional-planned-travel-notes')
    assert_equal patient.user_defined_id_statelocal, json_response['identifier'].find { |i| i['system'].include? 'state-local-id' }['value']
  end

  test 'should get patient via show using _format parameter' do
    get(
      '/fhir/r4/Patient/1?' + { _format: 'application/fhir+json' }.to_param,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}" }
    )
    assert_response :ok
  end

  test 'should get observation via show' do
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

  test 'should get QuestionnaireResponse via show' do
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

  test 'should be 404 via show when requesting unsupported resource' do
    get(
      '/fhir/r4/FooBar/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'should be forbidden via show' do
    get(
      '/fhir/r4/Patient/9',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: patients within exact jurisdiction should be accessible' do
    # Same jurisdiction
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
  end

  test 'SYSTEM FLOW: patients within subjurisdictions should be accessible' do
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

  test 'SYSTEM FLOW: patients outside of jurisdiction should NOT be accessible' do
    # Update jurisdiction to be out of scope
    Patient.find_by(id: 1).update!(jurisdiction_id: 1)
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

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

  test 'USER FLOW: should be 403 forbidden when user does not have api access enabled via show' do
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

  #----- create tests -----

  test 'should be unauthorized via create' do
    post '/fhir/r4/Patient'
    assert_response :unauthorized
  end

  test 'SYSTEM FLOW: should create Patient via create' do
    patient = Patient.find_by(id: 1)
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
    assert_equal 'USA, State 1',
                 json_response['extension'].find { |e| e['url'] == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }['valueString']
    assert_equal "/fhir/r4/Patient/#{id}", json_response['contained'].first['target'].first['reference']
    assert_equal @system_patient_read_write_app.uid, json_response['contained'].first['agent'].first['who']['identifier']['value']
    assert_equal @system_patient_read_write_app.name, json_response['contained'].first['agent'].first['who']['display']
    assert_equal patient.primary_telephone_type, fhir_ext_str(json_response['telecom'].first, 'phone-type')
    assert_equal patient.secondary_telephone_type, fhir_ext_str(json_response['telecom'].second, 'phone-type')
    assert_equal patient.monitoring_plan, fhir_ext_str(json_response, 'monitoring-plan')
    assert_equal patient.assigned_user, fhir_ext_pos_int(json_response, 'assigned-user')
    assert_equal patient.additional_planned_travel_start_date.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'additional-planned-travel-start-date')
    assert_equal patient.port_of_origin, fhir_ext_str(json_response, 'port-of-origin')
    assert_equal patient.date_of_departure.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-departure')
    assert_equal patient.flight_or_vessel_number, fhir_ext_str(json_response, 'flight-or-vessel-number')
    assert_equal patient.flight_or_vessel_carrier, fhir_ext_str(json_response, 'flight-or-vessel-carrier')
    assert_equal patient.date_of_arrival.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-arrival')
    assert_equal patient.exposure_notes, fhir_ext_str(json_response, 'exposure-notes')
    assert_equal patient.travel_related_notes, fhir_ext_str(json_response, 'travel-related-notes')
    assert_equal patient.additional_planned_travel_related_notes, fhir_ext_str(json_response, 'additional-planned-travel-notes')
    assert_equal patient.user_defined_id_statelocal, json_response['identifier'].find { |i| i['system'].include? 'state-local-id' }['value']
  end

  test 'USER FLOW: should create Patient via create' do
    patient = Patient.find_by(id: 1)
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
    assert_equal 'state1_epi@example.com', h.first.created_by
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert response.headers['Location'].ends_with?(json_response['id'].to_s)
    assert_equal 'USA, State 1',
                 json_response['extension'].find { |e| e['url'] == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }['valueString']
    assert_equal "/fhir/r4/Patient/#{id}", json_response['contained'].first['target'].first['reference']
    assert_equal Patient.find_by(id: id).creator_id, json_response['contained'].first['agent'].first['who']['identifier']['value']
    assert_equal Patient.find_by(id: id).creator.email, json_response['contained'].first['agent'].first['who']['display']
    assert_equal patient.primary_telephone_type, fhir_ext_str(json_response['telecom'].first, 'phone-type')
    assert_equal patient.secondary_telephone_type, fhir_ext_str(json_response['telecom'].second, 'phone-type')
    assert_equal patient.monitoring_plan, fhir_ext_str(json_response, 'monitoring-plan')
    assert_equal patient.assigned_user, fhir_ext_pos_int(json_response, 'assigned-user')
    assert_equal patient.additional_planned_travel_start_date.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'additional-planned-travel-start-date')
    assert_equal patient.port_of_origin, fhir_ext_str(json_response, 'port-of-origin')
    assert_equal patient.date_of_departure.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-departure')
    assert_equal patient.flight_or_vessel_number, fhir_ext_str(json_response, 'flight-or-vessel-number')
    assert_equal patient.flight_or_vessel_carrier, fhir_ext_str(json_response, 'flight-or-vessel-carrier')
    assert_equal patient.date_of_arrival.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-arrival')
    assert_equal patient.exposure_notes, fhir_ext_str(json_response, 'exposure-notes')
    assert_equal patient.travel_related_notes, fhir_ext_str(json_response, 'travel-related-notes')
    assert_equal patient.additional_planned_travel_related_notes, fhir_ext_str(json_response, 'additional-planned-travel-notes')
  end

  test 'should calculate Patient age via create' do
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

  test 'should be 415 when bad content type header via create' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'foo/bar' }
    )
    assert_response :unsupported_media_type
  end

  test 'should be bad request via create due to invalid JSON' do
    post(
      '/fhir/r4/Patient',
      env: { 'RAW_POST_DATA' => '{ "foo", "bar" }' },
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'Invalid JSON in request body', json_response['issue'][0]['diagnostics']
  end

  test 'should be bad request via create due to non-FHIR' do
    post(
      '/fhir/r4/Patient',
      params: { foo: 'bar' }.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
  end

  test 'should be bad request via create with invalid FHIR' do
    @patient_1.active = 1
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_match(/Patient.active/, json_response['issue'][0]['diagnostics'])
  end

  test 'should be bad request via create with multiple FHIR errors' do
    @patient_1.active = [1, 2]
    @patient_1.telecom[0].value = [1, 2]
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal json_response['issue'].length, 4
    assert_match(/Patient.active/, json_response['issue'][0]['diagnostics'])
    assert_match(/Patient.active/, json_response['issue'][1]['diagnostics'])
    assert_match(/Patient.active/, json_response['issue'][2]['diagnostics'])
    assert_match(/ContactPoint.value/, json_response['issue'][3]['diagnostics'])
  end

  test 'should be 404 not found via create due to unsupported resource' do
    post(
      '/fhir/r4/FooBar',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'should be unprocessable entity via create with validation errors' do
    post(
      '/fhir/r4/Patient',
      params: IO.read(file_fixture('fhir_invalid_patient.json')),
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    msg = 'Expected validation error on '
    assert_equal 18, errors.length
    assert(errors.any?(/Invalid.*Monitoring Plan/), msg + 'Monitoring Plan')
    assert(errors.any?(/Old York.*State/), msg + 'State')
    assert(errors.any?(/0000.*Ethnicity/), msg + 'Ethnicity')
    assert(errors.any?(/High noon.*Preferred Contact Time/), msg + 'Preferred Contact Time')
    assert(errors.any?(/On FHIR.*Sex/), msg + 'Sex')
    assert(errors.any?(/Dumbphone.*Telephone Type/), msg + 'Phone Type')
    assert(errors.any?(/123.*Primary Telephone/), msg + 'Primary Telephone')
    assert(errors.any?(/Date of Birth/), msg + 'Date of Birth')
    assert(errors.any?(/Last Date of Exposure/), msg + 'Last Date of Exposure')
    assert(errors.any?(/1492.*Symptom Onset/), msg + 'Symptom Onset')
    assert(errors.any?(/1776.*Additional Planned Travel Start Date/), msg + 'Additional Planned Travel Start Date')
    assert(errors.any?(/2020-01-32.*Date of Departure/), msg + 'Date of Departure')
    assert(errors.any?(/9999-99-99.*Date of Arrival/), msg + 'Date of Arrival')
    assert(errors.any?(/Last Name/), msg + 'Last Name')
    assert(errors.any?(/10000.*Assigned User/), msg + 'Assigned User')
    assert(errors.any?(/Email.*Primary Contact Method/), msg + 'Email')
  end

  test 'should group Patients in households with matching phone numbers' do
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

  test 'should group Patients in households with matching emails' do
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

  test 'should make Patient a self reporter if no matching number or email' do
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

  #----- update tests -----

  test 'should be unauthorized via update' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
  end

  test 'should update Patient via update' do
    patient_id = 1
    patient = Patient.find_by(id: 2)
    resource_path = "/fhir/r4/Patient/#{patient_id}"
    put(
      resource_path,
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
    assert_equal 4.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'last-date-of-exposure' }.first['valueDate']
    assert_equal 3.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
    assert_equal 'USA, State 1, County 1',
                 json_response['extension'].find { |e| e['url'] == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }['valueString']
    assert_equal resource_path, json_response['contained'].first['target'].first['reference']
    assert_equal Patient.find_by(id: patient_id).creator_id, json_response['contained'].first['agent'].first['who']['identifier']['value']
    assert_equal Patient.find_by(id: patient_id).creator.email, json_response['contained'].first['agent'].first['who']['display']
    assert_equal patient.primary_telephone_type, fhir_ext_str(json_response['telecom'].first, 'phone-type')
    assert_equal patient.secondary_telephone_type, fhir_ext_str(json_response['telecom'].second, 'phone-type')
    assert_equal patient.monitoring_plan, fhir_ext_str(json_response, 'monitoring-plan')
    assert_equal patient.assigned_user, fhir_ext_pos_int(json_response, 'assigned-user')
    assert_equal patient.additional_planned_travel_start_date.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'additional-planned-travel-start-date')
    assert_equal patient.port_of_origin, fhir_ext_str(json_response, 'port-of-origin')
    assert_equal patient.date_of_departure.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-departure')
    assert_equal patient.flight_or_vessel_number, fhir_ext_str(json_response, 'flight-or-vessel-number')
    assert_equal patient.flight_or_vessel_carrier, fhir_ext_str(json_response, 'flight-or-vessel-carrier')
    assert_equal patient.date_of_arrival.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-arrival')
    assert_equal patient.exposure_notes, fhir_ext_str(json_response, 'exposure-notes')
    assert_equal patient.travel_related_notes, fhir_ext_str(json_response, 'travel-related-notes')
    assert_equal patient.additional_planned_travel_related_notes, fhir_ext_str(json_response, 'additional-planned-travel-notes')
    assert_equal patient.user_defined_id_statelocal, json_response['identifier'].find { |i| i['system'].include? 'state-local-id' }['value']
  end

  test 'should update Patient via update and set omitted fields to nil ' do
    # Possible update request that omits all fields that can be updated except for the "active" field.
    patient_update = {
      'id' => @patient_2.id,
      'birthDate' => @patient_2.birthDate,
      'name' => @patient_2.name,
      'address' => @patient_2.address,
      'extension' => @patient_2.extension.find { |e| e.url.include? 'last-date-of-exposure' },
      'active' => false,
      'resourceType' => 'Patient'
    }

    put(
      '/fhir/r4/Patient/1',
      params: patient_update.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    p = Patient.find_by(id: 1)

    assert_not p.nil?
    assert_equal 'Patient', json_response['resourceType']
    assert_equal([], json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' })
    assert_equal([], json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' })
    assert_equal([], json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' })
    assert_equal false, json_response['active']
  end

  test 'should properly close Patient record via update' do
    # Possible update request that omits many fields but sets active to false
    patient_update = {
      'id' => @patient_2.id,
      'birthDate' => @patient_2.birthDate,
      'name' => @patient_2.name,
      'address' => @patient_2.address,
      'extension' => @patient_2.extension.find { |e| e.url.include? 'last-date-of-exposure' },
      'active' => false,
      'resourceType' => 'Patient',
      'telecom' => [
        {
          "system": 'email',
          "value": '2966977816fake@example.com',
          "rank": 1
        }
      ]
    }

    put(
      '/fhir/r4/Patient/1',
      params: patient_update.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    p = Patient.find_by(id: 1)

    assert_not p.nil?

    # Record should be closed
    assert_not json_response['active']
    assert_not p.monitoring

    # Closed at date should have been set to today
    assert_equal DateTime.now.to_date, p.closed_at&.to_date
  end

  test 'should be bad request via update due to invalid JSON' do
    put(
      '/fhir/r4/Patient/1',
      env: { 'RAW_POST_DATA' => '{ "foo", "bar" }' },
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'Invalid JSON in request body', json_response['issue'][0]['diagnostics']
  end

  test 'should be bad request via update due to bad fhir' do
    put(
      '/fhir/r4/Patient/1',
      params: { foo: 'bar' }.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
  end

  test 'should be bad request via update with invalid FHIR' do
    @patient_1.active = 1
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_match(/Patient.active/, json_response['issue'][0]['diagnostics'])
  end

  test 'should be bad request via update with multiple FHIR errors' do
    @patient_1.active = [1, 2]
    @patient_1.telecom[0].value = [1, 2]
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal json_response['issue'].length, 4
    assert_match(/Patient.active/, json_response['issue'][0]['diagnostics'])
    assert_match(/Patient.active/, json_response['issue'][1]['diagnostics'])
    assert_match(/Patient.active/, json_response['issue'][2]['diagnostics'])
    assert_match(/ContactPoint.value/, json_response['issue'][3]['diagnostics'])
  end

  test 'should be 404 not found via update due to unsupported resource' do
    put(
      '/fhir/r4/FooBar/9',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'should be unprocessable entity via update with validation errors' do
    put(
      '/fhir/r4/Patient/1',
      params: IO.read(file_fixture('fhir_invalid_patient.json')),
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    errors = json_response['issue'].map { |i| i['diagnostics'] }

    msg = 'Expected validation error on '
    assert_equal 18, errors.length
    assert(errors.any?(/Invalid.*Monitoring Plan/), msg + 'Monitoring Plan')
    assert(errors.any?(/Old York.*State/), msg + 'State')
    assert(errors.any?(/0000.*Ethnicity/), msg + 'Ethnicity')
    assert(errors.any?(/High noon.*Preferred Contact Time/), msg + 'Preferred Contact Time')
    assert(errors.any?(/On FHIR.*Sex/), msg + 'Sex')
    assert(errors.any?(/Dumbphone.*Telephone Type/), msg + 'Phone Type')
    assert(errors.any?(/123.*Primary Telephone/), msg + 'Primary Telephone')
    assert(errors.any?(/Date of Birth/), msg + 'Date of Birth')
    assert(errors.any?(/Last Date of Exposure/), msg + 'Last Date of Exposure')
    assert(errors.any?(/1492.*Symptom Onset/), msg + 'Symptom Onset')
    assert(errors.any?(/1776.*Additional Planned Travel Start Date/), msg + 'Additional Planned Travel Start Date')
    assert(errors.any?(/2020-01-32.*Date of Departure/), msg + 'Date of Departure')
    assert(errors.any?(/9999-99-99.*Date of Arrival/), msg + 'Date of Arrival')
    assert(errors.any?(/Last Name/), msg + 'Last Name')
    assert(errors.any?(/10000.*Assigned User/), msg + 'Assigned User')
    assert(errors.any?(/Email.*Primary Contact Method/), msg + 'Email')
  end

  test 'should be forbidden via update' do
    put(
      '/fhir/r4/Patient/9',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'SYSTEM FLOW: should be unprocessable entity via update with invalid jurisdiction path' do
    @patient_1.extension.find { |e| e.url == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }.valueString = 'USA, State 2'
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['issue'].length
    assert(json_response['issue'][0]['diagnostics'].include?('Jurisdiction must be within'))
  end

  test 'USER FLOW: should be unprocessable entity via update with invalid jurisdiction path' do
    @patient_1.extension.find { |e| e.url == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }.valueString = 'USA, State 2'
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['issue'].length
    assert(json_response['issue'][0]['diagnostics'].include?('Jurisdiction must be within'))
  end

  test 'should update Patient via patch update' do
    patch = [
      { 'op': 'remove', 'path': '/communication/0/language' },
      { 'op': 'add', 'path': '/address/0/line/-', 'value': 'Unit 123' },
      { 'op': 'replace', 'path': '/name/0/family', 'value': 'Foo' }
    ]
    patch(
      '/fhir/r4/Patient/1',
      params: patch.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/json-patch+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    assert_nil json_response['communication']
    assert_equal 'Unit 123', json_response['address'][0]['line'][1]
    assert_equal 'Foo', json_response['name'][0]['family']
  end

  test 'should be bad request when patch update is invalid' do
    patch = [{ 'op': 'replace', 'path': '/uh/oh/path', 'value': 'Foo' }]
    patch(
      '/fhir/r4/Patient/1',
      params: patch.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/json-patch+json' }
    )
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'OperationOutcome', json_response['resourceType']
  end

  test 'should be 415 when bad content type header via patch update' do
    patch(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'foo/bar' }
    )
    assert_response :unsupported_media_type
  end

  #----- search tests -----

  test 'should be unauthorized via search' do
    get '/fhir/r4/Patient?family=Kirlin44'
    assert_response :unauthorized
  end

  test 'should be unauthorized via search write only' do
    get(
      '/fhir/r4/Patient?family=Kirlin44',
      headers: { 'Authorization': "Bearer #{@system_patient_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

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

  test 'should find QuestionnaireResponses for a Patient via search' do
    get(
      '/fhir/r4/QuestionnaireResponse?subject=Patient/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'QuestionnaireResponse', json_response['entry'].first['resource']['resourceType']
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

  test 'should find no QuestionnaireResponses for an invalid Patient via search' do
    get(
      '/fhir/r4/QuestionnaireResponse?subject=Patient/blah',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'should find Patient via search by _id' do
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

  test 'should find Patient via search on existing family' do
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

  test 'should find no Patients via search on non-existing family' do
    get(
      '/fhir/r4/Patient?family=foo',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'should find Patient via search on given' do
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

  test 'should find Patient via search on telecom' do
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

  test 'should find Patient via search on email' do
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

  test 'should get Bundle via search without params' do
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

  test 'should be 404 via search when requesting unsupported resource' do
    get(
      '/fhir/r4/FooBar?email=grazyna%40example.com',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  test 'should get patients with default count via search' do
    get(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'http://www.example.com/fhir/r4/Patient?page=2', json_response['link'][0]['url']
  end

  test 'should get patients with count as 100 via search' do
    get(
      '/fhir/r4/Patient?_count=100',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end

  test 'should only get summary with count as 0 via search' do
    get(
      '/fhir/r4/Patient?_count=0',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end

  #----- all tests -----

  test 'should be unauthorized via all' do
    get '/fhir/r4/Patient/1/$everything'
    assert_response :unauthorized
  end

  test 'should get Bundle via all' do
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

  #----- capability_statement tests -----

  test 'should get CapabilityStatement unauthorized via capability_statement' do
    get(
      '/fhir/r4/metadata',
      headers: { 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end

  test 'should get CapabilityStatement authorized via capability_statement' do
    get(
      '/fhir/r4/metadata',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal ADMIN_OPTIONS['version'], json_response['software']['version']
  end

  #----- well_known tests -----

  test 'should get well known statement unauthorized via well_known' do
    get(
      '/fhir/r4/.well-known/smart-configuration',
      headers: { 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal "#{root_url}oauth/authorize", json_response['authorization_endpoint']
  end

  test 'should get well known statement authorized via well_known' do
    get(
      '/fhir/r4/.well-known/smart-configuration',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal "#{root_url}oauth/authorize", json_response['authorization_endpoint']
  end

  private

  def fhir_ext(obj, ext_id)
    obj['extension'].find { |e| e['url'].include? ext_id }
  end

  def fhir_ext_str(obj, ext_id)
    ext = fhir_ext(obj, ext_id)
    ext && ext['valueString']
  end

  def fhir_ext_date(obj, ext_id)
    ext = fhir_ext(obj, ext_id)
    ext && ext['valueDate']
  end

  def fhir_ext_pos_int(obj, ext_id)
    ext = fhir_ext(obj, ext_id)
    ext && ext['valuePositiveInt']
  end
end
# rubocop:enable Metrics/ClassLength
