# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
require 'test_helper'
require 'rspec/mocks/minitest_integration'

class ApiControllerTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    setup_patients
    setup_user_applications
    setup_system_applications
    setup_system_tokens
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

    # Create OAuth applications
    @user_everything_app = OauthApplication.create(
      name: 'user-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.* user/QuestionnaireResponse.read user/Observation.read user/RelatedPerson.* user/Immunization.*'
    )

    # Create access tokens
    @user_patient_token_rw = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application_id: @user_patient_read_write_app.id,
      scopes: 'user/Patient.*'
    )

    # Create access tokens
    @user_everything_token = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application_id: @user_everything_app.id,
      scopes: 'user/Patient.* user/QuestionnaireResponse.read user/Observation.read user/RelatedPerson.* user/Immunization.*'
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

    @system_related_person_read_write_app = OauthApplication.create(
      name: 'system-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/RelatedPerson.*',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_related_person_read_app = OauthApplication.create(
      name: 'system-test-patient-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/RelatedPerson.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_related_person_write_app = OauthApplication.create(
      name: 'system-test-patient-w',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/RelatedPerson.write',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_immunization_read_write_app = OauthApplication.create(
      name: 'system-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Immunization.*',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_immunization_read_app = OauthApplication.create(
      name: 'system-test-patient-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Immunization.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_immunization_write_app = OauthApplication.create(
      name: 'system-test-patient-w',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Immunization.write',
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
      scopes: 'system/Patient.* system/QuestionnaireResponse.read system/Observation.read system/RelatedPerson.* system/Immunization.*',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )
  end

  def setup_system_tokens
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
    @system_related_person_token_rw = Doorkeeper::AccessToken.create(
      application: @system_related_person_read_write_app,
      scopes: 'system/RelatedPerson.*'
    )
    @system_related_person_token_r = Doorkeeper::AccessToken.create(
      application: @system_related_person_read_app,
      scopes: 'system/RelatedPerson.read'
    )
    @system_related_person_token_w = Doorkeeper::AccessToken.create(
      application: @system_related_person_write_app,
      scopes: 'system/RelatedPerson.write'
    )
    @system_immunization_token_rw = Doorkeeper::AccessToken.create(
      application: @system_immunization_read_write_app,
      scopes: 'system/Immunization.*'
    )
    @system_immunization_token_r = Doorkeeper::AccessToken.create(
      application: @system_immunization_read_app,
      scopes: 'system/Immunization.read'
    )
    @system_immunization_token_w = Doorkeeper::AccessToken.create(
      application: @system_immunization_write_app,
      scopes: 'system/Immunization.write'
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
      scopes: 'system/Patient.* system/QuestionnaireResponse.read system/Observation.read system/RelatedPerson.* system/Immunization.*'
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
      secondary_telephone_type: 'Landline',
      black_or_african_american: true,
      asian: true,
      continuous_exposure: true,
      last_date_of_exposure: nil
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

  test 'should not be able to create RelatedPerson resource with RelatedPerson read scope' do
    post(
      '/fhir/r4/RelatedPerson',
      headers: { 'Authorization': "Bearer #{@system_related_person_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to create RelatedPerson resource with Observation scope' do
    post(
      '/fhir/r4/RelatedPerson',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to create RelatedPerson resource with QuestionnaireResponse scope' do
    post(
      '/fhir/r4/RelatedPerson',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to update RelatedPerson resource with RelatedPerson read scope' do
    put(
      '/fhir/r4/RelatedPerson/1',
      headers: { 'Authorization': "Bearer #{@system_related_person_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to update RelatedPerson resource with Observation scope' do
    put(
      '/fhir/r4/RelatedPerson/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to update RelatedPerson resource with QuestionnaireResponse scope' do
    put(
      '/fhir/r4/RelatedPerson/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read RelatedPerson resource with RelatedPerson write only scope' do
    get(
      '/fhir/r4/RelatedPerson/1',
      headers: { 'Authorization': "Bearer #{@system_related_person_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read RelatedPerson resource with Observation scope' do
    get(
      '/fhir/r4/RelatedPerson/1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read RelatedPerson resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/RelatedPerson/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to search RelatedPerson resource with RelatedPerson write only scope' do
    get(
      '/fhir/r4/RelatedPerson?_id=1',
      headers: { 'Authorization': "Bearer #{@system_related_person_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to search RelatedPerson resource with Observation scope' do
    get(
      '/fhir/r4/RelatedPerson?_id=1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to search RelatedPerson resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/RelatedPerson?_id=1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to create Immunization resource with Immunization read scope' do
    post(
      '/fhir/r4/Immunization',
      headers: { 'Authorization': "Bearer #{@system_immunization_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to create Immunization resource with Observation scope' do
    post(
      '/fhir/r4/Immunization',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to create Immunization resource with QuestionnaireResponse scope' do
    post(
      '/fhir/r4/Immunization',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to update Immunization resource with Immunization read scope' do
    put(
      '/fhir/r4/Immunization/1',
      headers: { 'Authorization': "Bearer #{@system_immunization_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to update Immunization resource with Observation scope' do
    put(
      '/fhir/r4/Immunization/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to update Immunization resource with QuestionnaireResponse scope' do
    put(
      '/fhir/r4/Immunization/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read Immunization resource with Immunization write only scope' do
    get(
      '/fhir/r4/Immunization/1',
      headers: { 'Authorization': "Bearer #{@system_immunization_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read Immunization resource with Observation scope' do
    get(
      '/fhir/r4/Immunization/1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to read Immunization resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Immunization/1',
      headers: { 'Authorization': "Bearer #{@system_response_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to search Immunization resource with Immunization write only scope' do
    get(
      '/fhir/r4/Immunization?_id=1',
      headers: { 'Authorization': "Bearer #{@system_immunization_token_w.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to search Immunization resource with Observation scope' do
    get(
      '/fhir/r4/Immunization?_id=1',
      headers: { 'Authorization': "Bearer #{@system_observation_token_r.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'should not be able to search Immunization resource with QuestionnaireResponse scope' do
    get(
      '/fhir/r4/Immunization?_id=1',
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

  #----- update tests -----

  test 'should be unauthorized via update' do
    get '/fhir/r4/Patient/1'
    assert_response :unauthorized
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

  test 'should be forbidden via update' do
    put(
      '/fhir/r4/Patient/9',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :forbidden
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

  test 'should be 404 via search when requesting unsupported resource' do
    get(
      '/fhir/r4/FooBar?email=grazyna%40example.com',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :not_found
  end

  #----- all tests -----

  test 'should be unauthorized via all' do
    get '/fhir/r4/Patient/1/$everything'
    assert_response :unauthorized
  end

  test 'should get Bundle via all' do
    patient = Patient.find_by_id(1)
    get(
      '/fhir/r4/Patient/1/$everything',
      headers: { 'Authorization': "Bearer #{@system_everything_token.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal patient.assessments.length + patient.laboratories.length + patient.close_contacts.length + 1, json_response['total']
    assert_equal 1, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Patient' }.count
    assert_equal patient.assessments.length, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'QuestionnaireResponse' }.count
    assert_equal patient.laboratories.length, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'Observation' }.count
    assert_equal patient.close_contacts.length, json_response['entry'].filter { |e| e['resource']['resourceType'] == 'RelatedPerson' }.count
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
