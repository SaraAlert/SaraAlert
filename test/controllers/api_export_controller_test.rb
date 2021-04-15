# frozen_string_literal: true

require 'test_helper'
require 'test_case'
require 'rspec/mocks/minitest_integration'

class ApiExportControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_system_applications
    allow_any_instance_of(PHDC::Serializer).to receive(:patient_to_phdc).and_return(Ox.dump(Ox::Document.new))
    Patient.find_by_id(1).update(case_status: 'Confirmed')
    Patient.find_by_id(2).update(case_status: 'Probable')
  end

  def setup_system_applications
    @shadow_user_jurisdiction = Jurisdiction.find_by(id: 2)
    shadow_user = User.create!(
      email: 'test@example.com',
      password: User.rand_gen,
      jurisdiction: @shadow_user_jurisdiction,
      force_password_change: false,
      api_enabled: true,
      role: 'public_health_enroller',
      is_api_proxy: true
    )
    shadow_user.lock_access!

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

    @system_patient_token_r = Doorkeeper::AccessToken.create(
      application: @system_patient_read_app,
      scopes: 'system/Patient.read'
    )

    @system_patient_token_w = Doorkeeper::AccessToken.create(
      application: @system_patient_write_app,
      scopes: 'system/Patient.write'
    )
  end

  test 'should be 401 unauthorized when token is not provided' do
    get '/export/nbs/patient'
    assert_response :unauthorized
  end

  test 'should be 403 forbidden when invalid scope' do
    get '/export/nbs/patient', headers: { 'Authorization': "Bearer #{@system_patient_token_w.token}" }
    assert_response :forbidden
  end

  test 'should be 406 not_acceptable accept header is not provided' do
    get '/export/nbs/patient', headers: { 'Authorization': "Bearer #{@system_patient_token_r.token}" }
    assert_response :not_acceptable
  end

  test 'should get no patients' do
    assert_expected_patients({}, { id: -1 })
  end

  test 'should get patients in isolation' do
    assert_expected_patients({ workflow: 'isolation' }, { isolation: true })
  end

  test 'should get patients in exposure' do
    assert_expected_patients({ workflow: 'exposure' }, { isolation: false })
  end

  test 'should get no patients with bad workflow' do
    assert_expected_patients({ workflow: 'foo' }, { id: -1 })
  end

  test 'should get active patients' do
    assert_expected_patients({ monitoring: 'true' }, { monitoring: true })
  end

  test 'should get inactive patients' do
    assert_expected_patients({ monitoring: 'false' }, { monitoring: false })
  end

  test 'should get no patients with bad monitoring' do
    assert_expected_patients({ monitoring: 'foo' }, { id: -1 })
  end

  test 'should get patients with confirmed case_status' do
    assert_expected_patients({ caseStatus: 'confirmed' }, { case_status: 'Confirmed' })
  end

  test 'should get patients with probable case_status' do
    assert_expected_patients({ caseStatus: 'probable' }, { case_status: 'Probable' })
  end

  test 'should get patients with confirmed,probable case_status' do
    assert_expected_patients({ caseStatus: 'confirmed,probable' }, { case_status: %w[Confirmed Probable] })
  end

  test 'should get no patients with bad case_status' do
    assert_expected_patients({ caseStatus: 'foo' }, { id: -1 })
  end

  test 'should get patients which are recently updated' do
    assert_expected_patients({ updatedAt: 2.days.ago }, ['patients.updated_at > ?', 2.days.ago])
  end

  test 'should get no patients with bad updated_at' do
    assert_expected_patients({ updatedAt: 'foo' }, { id: -1 })
  end

  test 'should ignore case in parameters' do
    assert_expected_patients({ monitoring: 'true ' }, { monitoring: true })
  end

  test 'should ignore whitespace in parameters' do
    assert_expected_patients({ caseStatus: 'ConFiRmed' }, { case_status: 'Confirmed' })
  end

  test 'should ignore whitespace between parameters' do
    assert_expected_patients({ caseStatus: 'confirmed, probable' }, { case_status: %w[Confirmed Probable] })
  end

  def assert_expected_patients(params, scope)
    get(
      '/export/nbs/patient',
      headers: { Authorization: "Bearer #{@system_patient_token_r.token}", Accept: 'application/zip' },
      params: params
    )
    assert_response :ok
    ids = []
    Zip::InputStream.open(StringIO.new(response.body)) do |io|
      while (entry = io.get_next_entry)
        ids << entry.name[%r{/(\d+)\.xml}, 1].to_i
      end
    end
    expected_ids = Jurisdiction
                   .find_by_id(@shadow_user_jurisdiction)
                   .all_patients_excluding_purged
                   .where(scope)
                   .pluck(:id)
    assert_equal expected_ids.sort, ids.sort
  end
end
