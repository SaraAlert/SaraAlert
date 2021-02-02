# frozen_string_literal: true

require 'test_case'

class PublicHealthControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  test 'patients authorization' do
    post :patients
    assert_redirected_to(new_user_session_path)

    %i[admin_user analyst_user enroller_user].each do |role|
      user = create(role)
      sign_in user
      post :patients
      assert_redirected_to @controller.root_url
      sign_out user
    end

    %i[public_health_user public_health_enroller_user contact_tracer_user super_user].each do |role|
      Jurisdiction.where(path: ['USA', 'USA, State 1', 'USA, State 1, County 1']).find_each do |user_jur|
        user = create(role, jurisdiction: user_jur)
        sign_in user

        error = assert_raises(ActionController::ParameterMissing) do
          post :patients
        end
        assert_includes(error.message, 'query')

        error = assert_raises(ActionController::ParameterMissing) do
          post :patients, params: { query: { tab: 'all' } }, as: :json
        end
        assert_includes(error.message, 'workflow')

        error = assert_raises(ActionController::ParameterMissing) do
          post :patients, params: { query: { workflow: 'exposure' } }, as: :json
        end
        assert_includes(error.message, 'tab')

        sign_out user
      end
    end
  end

  test 'patients param validation' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA, State 1'))
    sign_in user

    post :patients, params: { query: { workflow: 'asdf', tab: 'all' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'reporting' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'isolation', tab: 'pui' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', jurisdiction: 'asdf' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', jurisdiction: Jurisdiction.find_by(path: 'USA, State 2').id } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', scope: 'fdsa' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', user: 'asdf' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', user: '0' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', user: '1000000' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', entries: '-1' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', page: '-1' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', order: 'asdf' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', direction: 'fdsa' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', order: 'name' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', direction: 'asc' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', order: '', direction: 'asc' } }, as: :json
    assert_response :bad_request

    post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic', order: 'name', direction: '' } }, as: :json
    assert_response :bad_request

    sign_out user
  end

  test 'patients by linelist' do
    Jurisdiction.where(path: ['USA, State 1', 'USA, State 1, County 1']).find_each do |user_jur|
      user = create(:public_health_user, jurisdiction: user_jur)
      sign_in user

      common_fields = %w[name state_local_id dob]

      post :patients, params: { query: { workflow: 'exposure', tab: 'symptomatic' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.exposure_symptomatic
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      monitoring_plan latest_report report_eligibility], json_response['fields']

      post :patients, params: { query: { workflow: 'exposure', tab: 'non_reporting' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.exposure_non_reporting
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      monitoring_plan latest_report report_eligibility], json_response['fields']

      post :patients, params: { query: { workflow: 'exposure', tab: 'asymptomatic' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.exposure_asymptomatic
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      monitoring_plan latest_report report_eligibility], json_response['fields']

      post :patients, params: { query: { workflow: 'exposure', tab: 'pui' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.exposure_under_investigation
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      public_health_action latest_report report_eligibility], json_response['fields']

      post :patients, params: { query: { workflow: 'exposure', tab: 'closed' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.monitoring_closed_without_purged.where(isolation: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user expected_purge_date reason_for_closure closed_at], json_response['fields']

      post :patients, params: { query: { workflow: 'exposure', tab: 'transferred_in' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user_jur.transferred_in_patients.where(isolation: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[transferred_from end_of_monitoring risk_level monitoring_plan transferred_at], json_response['fields']

      post :patients, params: { query: { workflow: 'exposure', tab: 'transferred_out' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user_jur.transferred_out_patients.where(isolation: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[transferred_to end_of_monitoring risk_level monitoring_plan transferred_at], json_response['fields']

      post :patients, params: { query: { workflow: 'exposure', tab: 'all' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.where(isolation: false, purged: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      monitoring_plan latest_report status report_eligibility], json_response['fields']

      post :patients, params: { query: { workflow: 'isolation', tab: 'requiring_review' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.isolation_requiring_review
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user extended_isolation symptom_onset monitoring_plan
                                      latest_report report_eligibility], json_response['fields']

      post :patients, params: { query: { workflow: 'isolation', tab: 'non_reporting' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.isolation_non_reporting
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user extended_isolation symptom_onset monitoring_plan
                                      latest_report report_eligibility], json_response['fields']

      post :patients, params: { query: { workflow: 'isolation', tab: 'reporting' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.isolation_reporting
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user extended_isolation symptom_onset monitoring_plan
                                      latest_report report_eligibility], json_response['fields']

      post :patients, params: { query: { workflow: 'isolation', tab: 'closed' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.monitoring_closed_without_purged.where(isolation: true)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user expected_purge_date reason_for_closure closed_at], json_response['fields']

      post :patients, params: { query: { workflow: 'isolation', tab: 'transferred_in' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user_jur.transferred_in_patients.where(isolation: true)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[transferred_from monitoring_plan transferred_at], json_response['fields']

      post :patients, params: { query: { workflow: 'isolation', tab: 'transferred_out' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user_jur.transferred_out_patients.where(isolation: true)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[transferred_to monitoring_plan transferred_at], json_response['fields']

      post :patients, params: { query: { workflow: 'isolation', tab: 'all' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.where(isolation: true, purged: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user extended_isolation symptom_onset monitoring_plan
                                      latest_report status report_eligibility], json_response['fields']

      post :patients, params: { query: { workflow: 'all', tab: 'closed' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.monitoring_closed_without_purged
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']

      post :patients, params: { query: { workflow: 'all', tab: 'transferred_in' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user_jur.transferred_in_patients
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']

      post :patients, params: { query: { workflow: 'all', tab: 'transferred_out' } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user_jur.transferred_out_patients
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']

      post :patients, params: { query: { workflow: 'all', tab: 'all', entries: 100 } }, as: :json
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.where(purged: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']

      sign_out user
    end
  end

  test 'patients by jurisdiction and assigned user' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA, State 1'))
    sign_in user

    jur = Jurisdiction.find_by(path: 'USA, State 1, County 1')

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'all' } }, as: :json
    JSON.parse(response.body)['linelist'].each do |patient|
      assert jur.subtree.pluck(:name).include?(patient['jurisdiction'])
    end

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'exact' } }, as: :json
    JSON.parse(response.body)['linelist'].each do |patient|
      assert_equal jur[:name], patient['jurisdiction']
    end

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', user: 'none' } }, as: :json
    JSON.parse(response.body)['linelist'].each do |patient|
      assert patient['assigned_user'].blank?
    end

    assigned_user = user.viewable_patients.where.not(assigned_user: nil).distinct.pluck(:assigned_user).first

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', user: assigned_user } }, as: :json
    JSON.parse(response.body)['linelist'].each do |patient|
      assert_equal assigned_user, patient['assigned_user']
    end

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'all', user: 'none' } }, as: :json
    JSON.parse(response.body)['linelist'].each do |patient|
      assert jur.subtree.pluck(:name).include?(patient['jurisdiction'])
      assert patient['assigned_user'].blank?
    end

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'exact', user: 'none' } }, as: :json
    JSON.parse(response.body)['linelist'].each do |patient|
      assert_equal jur[:name], patient['jurisdiction']
      assert patient['assigned_user'].blank?
    end

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'all', user: assigned_user } }, as: :json
    JSON.parse(response.body)['linelist'].each do |patient|
      assert jur.subtree.pluck(:name).include?(patient['jurisdiction'])
      assert_equal assigned_user, patient['assigned_user']
    end

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'exact', user: assigned_user } }, as: :json
    JSON.parse(response.body)['linelist'].each do |patient|
      assert_equal jur[:name], patient['jurisdiction']
      assert_equal assigned_user, patient['assigned_user']
    end

    sign_out user
  end

  test 'patients filtering' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA, State 1'))
    sign_in user

    filtered_patient = user.viewable_patients.where(isolation: false, purged: false).first
    post :patients, params: { query: { workflow: 'exposure', tab: 'all', search: filtered_patient[:first_name] } }, as: :json
    JSON.parse(response.body)['linelist'].each do |patient|
      assert patient['name'].include?(filtered_patient[:first_name])
    end

    sign_out user
  end

  test 'patients sorting' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA, State 1'))
    sign_in user

    order = 'name'

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', order: order, direction: 'asc' } }, as: :json
    patient_ids = user.viewable_patients.where(isolation: false, purged: false).order(:last_name, :first_name).pluck(:id)
    assert_equal patient_ids, (JSON.parse(response.body)['linelist'].map { |patient| patient['id'] })

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', order: order, direction: 'desc' } }, as: :json
    patient_ids = user.viewable_patients.where(isolation: false, purged: false).order(last_name: :desc, first_name: :desc).pluck(:id)
    assert_equal patient_ids, (JSON.parse(response.body)['linelist'].map { |patient| patient['id'] })

    sign_out user
  end

  test 'patients pagination' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA, State 1'))
    sign_in user

    entries = 5

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', entries: entries, page: 0 } }, as: :json
    page_0 = JSON.parse(response.body)
    assert_equal entries, page_0['linelist'].size
    assert_not_equal entries, page_0['total']

    post :patients, params: { query: { workflow: 'exposure', tab: 'all', entries: entries, page: 1 } }, as: :json
    page_1 = JSON.parse(response.body)
    assert_not_equal page_0, page_1

    sign_out user
  end

  test 'workflow counts' do
    get :workflow_counts
    assert_redirected_to(new_user_session_path)

    %i[admin_user analyst_user enroller_user].each do |role|
      user = create(role)
      sign_in user
      get :workflow_counts
      assert_redirected_to @controller.root_url
      sign_out user
    end

    %i[public_health_user public_health_enroller_user contact_tracer_user super_user].each do |role|
      Jurisdiction.where(path: ['USA', 'USA, State 1', 'USA, State 1, County 1']).find_each do |user_jur|
        user = create(role, jurisdiction: user_jur)
        sign_in user

        get :workflow_counts
        json_response = JSON.parse(response.body)

        assert_equal user.viewable_patients.where(isolation: false, purged: false).size, json_response['exposure']
        assert_equal user.viewable_patients.where(isolation: true, purged: false).size, json_response['isolation']

        sign_out user
      end
    end
  end

  test 'patient counts' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user

    post :patients_count, params: { query: { workflow: 'all', tab: 'all', jurisdiction: user.jurisdiction.id } }, as: :json
    assert_equal user.jurisdiction.all_patients_excluding_purged.size, JSON.parse(response.body)['count']

    sign_out user
  end

  test 'tab counts' do
    get :tab_counts, params: { workflow: 'exposure', tab: 'all' }
    assert_redirected_to(new_user_session_path)

    %i[admin_user analyst_user enroller_user].each do |role|
      user = create(role)
      sign_in user
      get :tab_counts, params: { workflow: 'exposure', tab: 'all' }
      assert_redirected_to @controller.root_url
      sign_out user
    end

    %i[public_health_user public_health_enroller_user contact_tracer_user super_user].each do |role|
      Jurisdiction.where(path: ['USA', 'USA, State 1', 'USA, State 1, County 1']).find_each do |user_jur|
        user = create(role, jurisdiction: user_jur)
        sign_in user

        get :tab_counts, params: { workflow: 'asdf', tab: 'all' }
        assert_response :bad_request

        get :tab_counts, params: { workflow: 'exposure', tab: 'requiring_review' }
        assert_response :bad_request

        get :tab_counts, params: { workflow: 'isolation', tab: 'pui' }
        assert_response :bad_request

        get :tab_counts, params: { workflow: 'exposure', tab: 'symptomatic' }
        assert_equal user.viewable_patients.exposure_symptomatic.size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'exposure', tab: 'non_reporting' }
        assert_equal user.viewable_patients.exposure_non_reporting.size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'exposure', tab: 'asymptomatic' }
        assert_equal user.viewable_patients.exposure_asymptomatic.size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'exposure', tab: 'pui' }
        assert_equal user.viewable_patients.exposure_under_investigation.size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'exposure', tab: 'closed' }
        assert_equal user.viewable_patients.monitoring_closed_without_purged.where(isolation: false).size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'exposure', tab: 'transferred_in' }
        assert_equal user.jurisdiction.transferred_in_patients.where(isolation: false).size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'exposure', tab: 'transferred_out' }
        assert_equal user.jurisdiction.transferred_out_patients.where(isolation: false).size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'exposure', tab: 'all' }
        assert_equal user.viewable_patients.where(isolation: false, purged: false).size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'isolation', tab: 'requiring_review' }
        assert_equal user.viewable_patients.isolation_requiring_review.size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'isolation', tab: 'non_reporting' }
        assert_equal user.viewable_patients.isolation_non_reporting.size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'isolation', tab: 'reporting' }
        assert_equal user.viewable_patients.isolation_reporting.size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'isolation', tab: 'closed' }
        assert_equal user.viewable_patients.monitoring_closed_without_purged.where(isolation: true).size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'isolation', tab: 'transferred_in' }
        assert_equal user.jurisdiction.transferred_in_patients.where(isolation: true).size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'isolation', tab: 'transferred_out' }
        assert_equal user.jurisdiction.transferred_out_patients.where(isolation: true).size, JSON.parse(response.body)['total']

        get :tab_counts, params: { workflow: 'isolation', tab: 'all' }
        assert_equal user.viewable_patients.where(isolation: true, purged: false).size, JSON.parse(response.body)['total']

        sign_out user
      end
    end
  end

  test 'advanced filter quarantine option ten_day contains patient when querying from different timezones' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user, monitoring: true, last_date_of_exposure: 15.days.ago)
    assessment = create(:assessment, patient: patient, symptomatic: false)
    js_timezone_offsets = [-120, -480, -720, 300, 360, 420, 480, 660]
    (10..15).to_a.each do |lde|
      patient.update(last_date_of_exposure: lde.days.ago)
      assessment.update(created_at: 1.days.ago) if lde == 14
      assessment.update(created_at: 2.days.ago) if lde == 15
      js_timezone_offsets.each do |offset|
        patients = @controller.send(:advanced_filter_quarantine_option, user.viewable_patients, { value: true }, offset, :ten_day)
        assert_equal(patients.count, 1)
      end
    end
  end

  test 'advanced filter quarantine option seven_day contains patient when querying from different timezones' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user, monitoring: true, last_date_of_exposure: 15.days.ago)
    assessment = create(:assessment, patient: patient, symptomatic: false)
    laboratory = create(:laboratory, patient: patient, result: 'negative', lab_type: 'ANTIGEN', specimen_collection: DateTime.now)
    js_timezone_offsets = [-120, -480, -720, 300, 360, 420, 480, 660]
    (7..12).to_a.each do |lde|
      patient.update(last_date_of_exposure: lde.days.ago)
      if lde > 9
        assessment.update(created_at: 3.days.ago)
        laboratory.update(specimen_collection: 3.days.ago)
      end
      js_timezone_offsets.each do |offset|
        patients = @controller.send(:advanced_filter_quarantine_option, user.viewable_patients, { value: true }, offset, :seven_day)
        assert_equal(patients.count, 1)
      end
    end
  end
end
