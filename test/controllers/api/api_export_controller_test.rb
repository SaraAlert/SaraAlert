# frozen_string_literal: true

require 'test_helper'
require 'test_case'
require 'rspec/mocks/minitest_integration'

class ApiExportControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_system_applications
    allow_any_instance_of(PHDC::Serializer).to receive(:patient_to_phdc).and_return(Ox.dump(Ox::Document.new))
  end

  def setup_system_applications
    @shadow_user = create(:public_health_enroller_user, is_api_proxy: true, api_enabled: true)
    @shadow_user_jurisdiction = @shadow_user.jurisdiction_id
    @shadow_user.lock_access!

    @nbs_read_app = create(
      :oauth_application,
      user_id: @shadow_user,
      jurisdiction_id: @shadow_user_jurisdiction,
      scopes: 'system/Patient.read system/QuestionnaireResponse.read'
    )

    @system_patient_write_app = create(
      :oauth_application,
      user_id: @shadow_user,
      jurisdiction_id: @shadow_user_jurisdiction,
      scopes: 'system/Patient.write'
    )

    @nbs_read_token = Doorkeeper::AccessToken.create(
      application: @nbs_read_app,
      scopes: 'system/Patient.read system/QuestionnaireResponse.read'
    )

    @system_patient_token_w = Doorkeeper::AccessToken.create(
      application: @system_patient_write_app,
      scopes: 'system/Patient.write'
    )
  end

  test 'should be 401 unauthorized when token is not provided' do
    get '/api/nbs/patient'
    assert_response :unauthorized
  end

  test 'should be 403 forbidden when invalid scope' do
    get '/api/nbs/patient', headers: { Authorization: "Bearer #{@system_patient_token_w.token}" }
    assert_response :forbidden
  end

  test 'should be 406 not_acceptable accept header is not provided' do
    get '/api/nbs/patient', headers: { Authorization: "Bearer #{@nbs_read_token.token}" }
    assert_response :not_acceptable
  end

  test 'should get no patients' do
    assert_expected_patients({}, { id: -1 })
  end

  test 'should get patients in isolation' do
    create(:patient, creator: @shadow_user, isolation: true)
    create(:patient, creator: @shadow_user, isolation: false)
    assert_expected_patients({ workflow: 'isolation' }, { isolation: true })
  end

  test 'should get patients in exposure' do
    create(:patient, creator: @shadow_user, isolation: false)
    create(:patient, creator: @shadow_user, isolation: true)
    assert_expected_patients({ workflow: 'exposure' }, { isolation: false })
  end

  test 'should get no patients with bad workflow' do
    create(:patient, creator: @shadow_user)
    assert_expected_patients({ workflow: 'foo' }, { id: -1 })
  end

  test 'should get active patients' do
    create(:patient, creator: @shadow_user, monitoring: true)
    create(:patient, creator: @shadow_user, monitoring: false)
    assert_expected_patients({ monitoring: 'true' }, { monitoring: true })
  end

  test 'should get active patients with a boolean parameter' do
    create(:patient, creator: @shadow_user, monitoring: true)
    create(:patient, creator: @shadow_user, monitoring: false)
    assert_expected_patients({ monitoring: true }, { monitoring: true }, :json)
  end

  test 'should get inactive patients' do
    create(:patient, creator: @shadow_user, monitoring: true)
    create(:patient, creator: @shadow_user, monitoring: false)
    assert_expected_patients({ monitoring: 'false' }, { monitoring: false })
  end

  test 'should get no patients with bad monitoring' do
    create(:patient, creator: @shadow_user)
    assert_expected_patients({ monitoring: 'foo' }, { id: -1 })
  end

  test 'should get patients with confirmed case_status' do
    create(:patient, creator: @shadow_user, case_status: 'Confirmed')
    create(:patient, creator: @shadow_user, case_status: 'Unknown')
    assert_expected_patients({ caseStatus: 'confirmed' }, { case_status: 'Confirmed' })
  end

  test 'should get patients with confirmed,probable case_status' do
    create(:patient, creator: @shadow_user, case_status: 'Confirmed')
    create(:patient, creator: @shadow_user, case_status: 'Probable')
    create(:patient, creator: @shadow_user, case_status: 'Unknown')
    assert_expected_patients({ caseStatus: 'confirmed,probable' }, { case_status: %w[Confirmed Probable] })
  end

  test 'should get no patients with bad case_status' do
    create(:patient, creator: @shadow_user)
    assert_expected_patients({ caseStatus: 'foo' }, { id: -1 })
  end

  test 'should get patients which are recently updated' do
    create(:patient, creator: @shadow_user)
    old_patient = create(:patient, creator: @shadow_user, updated_at: 3.days.ago)
    old_patient.update(updated_at: 3.days.ago)
    assert_expected_patients({ updatedSince: 2.days.ago }, ['patients.updated_at > ?', 2.days.ago])
  end

  test 'should get patients by multiple parameters' do
    create(:patient, creator: @shadow_user, case_status: 'Confirmed', isolation: true)
    create(:patient, creator: @shadow_user, case_status: 'Unknown', isolation: false)
    create(:patient, creator: @shadow_user, case_status: 'Confirmed', isolation: false)
    create(:patient, creator: @shadow_user, case_status: 'Unknown', isolation: true)

    assert_expected_patients({ caseStatus: 'Confirmed', workflow: 'Isolation' }, { case_status: 'Confirmed', isolation: true })
  end

  test 'should get no patients with bad updated_at' do
    create(:patient, creator: @shadow_user)
    assert_expected_patients({ updatedSince: 'foo' }, { id: -1 })
  end

  test 'should ignore whitespace in parameters' do
    create(:patient, creator: @shadow_user, monitoring: true)
    assert_expected_patients({ monitoring: 'true ' }, { monitoring: true })
  end

  test 'should ignore case in parameters' do
    create(:patient, creator: @shadow_user, case_status: 'Confirmed')
    create(:patient, creator: @shadow_user, case_status: 'confirmed')
    assert_expected_patients({ caseStatus: 'ConFiRmed' }, { case_status: 'Confirmed' })
  end

  test 'should ignore whitespace between parameters' do
    create(:patient, creator: @shadow_user, case_status: 'Confirmed')
    create(:patient, creator: @shadow_user, case_status: 'Probable')
    assert_expected_patients({ caseStatus: 'confirmed, probable' }, { case_status: %w[Confirmed Probable] })
  end

  def assert_expected_patients(params, scope, type = nil)
    get(
      '/api/nbs/patient',
      headers: { Authorization: "Bearer #{@nbs_read_token.token}", Accept: 'application/zip' },
      params: params,
      as: type
    )
    assert_response :ok
    ids = []
    Zip::InputStream.open(StringIO.new(response.body)) do |io|
      while (entry = io.get_next_entry)
        ids << entry.name[%r{/(\d+)\.xml}, 1].to_i
      end
    end
    expected_ids = Jurisdiction
                   .find_by(id: @shadow_user_jurisdiction)
                   .all_patients_excluding_purged
                   .where(scope)
                   .pluck(:id)
    assert_equal expected_ids.sort, ids.sort
  end
end
