# frozen_string_literal: true

require 'test_case'

class ApiControllerTestCase < ActionDispatch::IntegrationTest
  def setup_logger
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
    @user_patient_read_write_app = create(
      :oauth_application,
      name: 'user-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.*'
    )

    # Create OAuth applications
    @user_everything_app = create(
      :oauth_application,
      name: 'user-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'user/Patient.* user/QuestionnaireResponse.read user/Observation.* user/RelatedPerson.* user/Immunization.* user/Provenance.read'
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
      scopes: 'user/Patient.* user/QuestionnaireResponse.read user/Observation.* user/RelatedPerson.* user/Immunization.* user/Provenance.read'
    )
  end

  # Sets up applications registered for system flow
  def setup_system_applications
    # Create "shadow user" that will is associated with the M2M OAuth apps
    shadow_user = create(
      :user,
      password: User.rand_gen,
      jurisdiction: Jurisdiction.find_by(id: 2),
      force_password_change: false,
      api_enabled: true,
      role: 'public_health_enroller',
      is_api_proxy: true
    )
    shadow_user.lock_access!

    # Create OAuth applications
    @system_patient_read_write_app = create(
      :oauth_application,
      name: 'system-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.*',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_read_app = create(
      :oauth_application,
      name: 'system-test-patient-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_write_app = create(
      :oauth_application,
      name: 'system-test-patient-w',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.write',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_related_person_read_write_app = create(
      :oauth_application,
      name: 'system-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/RelatedPerson.*',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_related_person_read_app = create(
      :oauth_application,
      name: 'system-test-patient-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/RelatedPerson.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_related_person_write_app = create(
      :oauth_application,
      name: 'system-test-patient-w',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/RelatedPerson.write',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_immunization_read_write_app = create(
      :oauth_application,
      name: 'system-test-patient-rw',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Immunization.*',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_immunization_read_app = create(
      :oauth_application,
      name: 'system-test-patient-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Immunization.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_immunization_write_app = create(
      :oauth_application,
      name: 'system-test-patient-w',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Immunization.write',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_provenance_read_app = create(
      :oauth_application,
      name: 'system-test-patient-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Provenance.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_observation_read_app = create(
      :oauth_application,
      name: 'system-test-observation-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_response_read_app = create(
      :oauth_application,
      name: 'system-test-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/QuestionnaireResponse.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_rw_observation_r_app = create(
      :oauth_application,
      name: 'system-test-patient-rw-observation-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.* system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_patient_rw_response_r_app = create(
      :oauth_application,
      name: 'system-test-patient-rw-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.* system/QuestionnaireResponse.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_observation_r_response_r_app = create(
      :oauth_application,
      name: 'system-test-observation-r-response-r',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/QuestionnaireResponse.read system/Observation.read',
      jurisdiction_id: 2,
      user_id: shadow_user.id
    )

    @system_everything_app = create(
      :oauth_application,
      name: 'system-test-everything',
      redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
      scopes: 'system/Patient.* system/QuestionnaireResponse.read system/Observation.* system/RelatedPerson.* system/Immunization.*',
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
    @system_provenance_token_r = Doorkeeper::AccessToken.create(
      application: @system_provenance_read_app,
      scopes: 'system/Provenance.read'
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
      scopes: 'user/Patient.* user/QuestionnaireResponse.read user/Observation.* user/RelatedPerson.* user/Immunization.* user/Provenance.read'
    )
  end

  # Sets up FHIR patients used for testing
  def setup_patients
    Patient.find_by(id: 1).update!(
      assigned_user: '1234',
      exposure_notes: 'exposure notes',
      travel_related_notes: 'travel notes',
      additional_planned_travel_related_notes: 'additional travel notes',
      follow_up_reason: 'Duplicate',
      follow_up_note: 'This is a follow up note.'
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
