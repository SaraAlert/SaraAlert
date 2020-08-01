# frozen_string_literal: true

require 'test_case'

class PublicHealthControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  test 'patients authorization' do
    get :patients
    assert_redirected_to(new_user_session_path)

    %i[admin_user analyst_user enroller_user].each do |role|
      user = create(role)
      sign_in user
      get :patients
      assert_redirected_to @controller.root_url
      sign_out user
    end

    %i[public_health_user public_health_enroller_user].each do |role|
      Jurisdiction.where(path: ['USA', 'USA, State 1', 'USA, State 1, County 1']).find_each do |user_jur|
        user = create(role, jurisdiction: user_jur)
        sign_in user

        error = assert_raises(ActionController::ParameterMissing) do
          get :patients
        end
        assert_includes(error.message, 'workflow')

        error = assert_raises(ActionController::ParameterMissing) do
          get :patients, params: { workflow: 'exposure' }
        end
        assert_includes(error.message, 'tab')

        sign_out user
      end
    end
  end

  test 'patients param validation' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.where(path: 'USA, State 1').first)
    sign_in user

    get :patients, params: { workflow: 'asdf', tab: 'all' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'reporting' }
    assert_response :bad_request

    get :patients, params: { workflow: 'isolation', tab: 'pui' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', jurisdiction: 'asdf' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', jurisdiction: Jurisdiction.where(path: 'USA, State 2').first }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', scope: 'fdsa' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', user: 'asdf' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', user: '0' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', user: '10000' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', entries: '-1' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', page: '-1' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', order: 'asdf' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', direction: 'fdsa' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', order: 'name' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', direction: 'asc' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', order: '', direction: 'asc' }
    assert_response :bad_request

    get :patients, params: { workflow: 'exposure', tab: 'symptomatic', order: 'name', direction: '' }
    assert_response :bad_request

    sign_out user
  end

  test 'patients by workflow and tab' do
    Jurisdiction.where(path: ['USA, State 1', 'USA, State 1, County 1']).find_each do |user_jur|
      user = create(:public_health_user, jurisdiction: user_jur)
      sign_in user

      common_fields = %w[name state_local_id sex dob]

      get :patients, params: { workflow: 'exposure', tab: 'symptomatic' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.exposure_symptomatic
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      monitoring_plan latest_report report_eligibility], json_response['fields']

      get :patients, params: { workflow: 'exposure', tab: 'non_reporting' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.exposure_non_reporting
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      monitoring_plan latest_report report_eligibility], json_response['fields']

      get :patients, params: { workflow: 'exposure', tab: 'asymptomatic' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.exposure_asymptomatic
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      monitoring_plan latest_report report_eligibility], json_response['fields']

      get :patients, params: { workflow: 'exposure', tab: 'pui' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.exposure_under_investigation
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      public_health_action latest_report report_eligibility], json_response['fields']

      get :patients, params: { workflow: 'exposure', tab: 'closed' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.monitoring_closed_without_purged.where(isolation: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user expected_purge_date reason_for_closure closed_at], json_response['fields']

      get :patients, params: { workflow: 'exposure', tab: 'transferred_in' }
      json_response = JSON.parse(response.body)
      patients = user.jurisdiction.transferred_in_patients.where(isolation: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[transferred_from end_of_monitoring risk_level monitoring_plan transferred_at], json_response['fields']

      get :patients, params: { workflow: 'exposure', tab: 'transferred_out' }
      json_response = JSON.parse(response.body)
      patients = user.jurisdiction.transferred_out_patients.where(isolation: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[transferred_to end_of_monitoring risk_level monitoring_plan transferred_at], json_response['fields']

      get :patients, params: { workflow: 'exposure', tab: 'all' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.where(isolation: false, purged: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user end_of_monitoring risk_level
                                      monitoring_plan latest_report status report_eligibility], json_response['fields']

      get :patients, params: { workflow: 'isolation', tab: 'requiring_review' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.isolation_requiring_review
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user monitoring_plan latest_report report_eligibility], json_response['fields']

      get :patients, params: { workflow: 'isolation', tab: 'non_reporting' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.isolation_non_reporting
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user monitoring_plan latest_report report_eligibility], json_response['fields']

      get :patients, params: { workflow: 'isolation', tab: 'reporting' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.isolation_reporting
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user monitoring_plan latest_report report_eligibility], json_response['fields']

      get :patients, params: { workflow: 'isolation', tab: 'closed' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.monitoring_closed_without_purged.where(isolation: true)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user expected_purge_date reason_for_closure closed_at], json_response['fields']

      get :patients, params: { workflow: 'isolation', tab: 'transferred_in' }
      json_response = JSON.parse(response.body)
      patients = user.jurisdiction.transferred_in_patients.where(isolation: true)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[transferred_from monitoring_plan transferred_at], json_response['fields']

      get :patients, params: { workflow: 'isolation', tab: 'transferred_out' }
      json_response = JSON.parse(response.body)
      patients = user.jurisdiction.transferred_out_patients.where(isolation: true)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[transferred_to monitoring_plan transferred_at], json_response['fields']

      get :patients, params: { workflow: 'isolation', tab: 'all' }
      json_response = JSON.parse(response.body)
      patients = user.viewable_patients.where(isolation: true, purged: false)
      assert_equal patients.order(:id).pluck(:id), json_response['linelist'].map { |patient| patient['id'] }.sort
      assert_equal patients.size, json_response['total']
      assert_equal common_fields + %w[jurisdiction assigned_user monitoring_plan latest_report status report_eligibility], json_response['fields']

      sign_out user
    end
  end

  test 'patients by jurisdiction and assigned user' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.where(path: 'USA, State 1').first)
    sign_in user

    jur = Jurisdiction.where(path: 'USA, State 1, County 1').first

    get :patients, params: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'all' }
    JSON.parse(response.body)['linelist'].each do |patient|
      assert jur.subtree.pluck(:name).include?(patient['jurisdiction'])
    end

    get :patients, params: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'exact' }
    JSON.parse(response.body)['linelist'].each do |patient|
      assert_equal jur[:name], patient['jurisdiction']
    end

    get :patients, params: { workflow: 'exposure', tab: 'all', user: 'none' }
    JSON.parse(response.body)['linelist'].each do |patient|
      assert patient['assigned_user'].blank?
    end

    assigned_user = user.viewable_patients.where.not(assigned_user: nil).distinct.pluck(:assigned_user).first

    get :patients, params: { workflow: 'exposure', tab: 'all', user: assigned_user }
    JSON.parse(response.body)['linelist'].each do |patient|
      assert_equal assigned_user, patient['assigned_user']
    end

    get :patients, params: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'all', user: 'none' }
    JSON.parse(response.body)['linelist'].each do |patient|
      assert jur.subtree.pluck(:name).include?(patient['jurisdiction'])
      assert patient['assigned_user'].blank?
    end

    get :patients, params: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'exact', user: 'none' }
    JSON.parse(response.body)['linelist'].each do |patient|
      assert_equal jur[:name], patient['jurisdiction']
      assert patient['assigned_user'].blank?
    end

    get :patients, params: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'all', user: assigned_user }
    JSON.parse(response.body)['linelist'].each do |patient|
      assert jur.subtree.pluck(:name).include?(patient['jurisdiction'])
      assert_equal assigned_user, patient['assigned_user']
    end

    get :patients, params: { workflow: 'exposure', tab: 'all', jurisdiction: jur[:id], scope: 'exact', user: assigned_user }
    JSON.parse(response.body)['linelist'].each do |patient|
      assert_equal jur[:name], patient['jurisdiction']
      assert_equal assigned_user, patient['assigned_user']
    end

    sign_out user
  end

  test 'patients filtering' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.where(path: 'USA, State 1').first)
    sign_in user

    filtered_patient = user.viewable_patients.where(isolation: false, purged: false).first
    get :patients, params: { workflow: 'exposure', tab: 'all', search: filtered_patient[:first_name] }
    JSON.parse(response.body)['linelist'].each do |patient|
      assert patient['name'].include?(filtered_patient[:first_name])
    end

    sign_out user
  end

  test 'patients sorting' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.where(path: 'USA, State 1').first)
    sign_in user

    order = 'name'

    get :patients, params: { workflow: 'exposure', tab: 'all', order: order, direction: 'asc' }
    patient_ids = user.viewable_patients.where(isolation: false, purged: false).order(:last_name, :first_name).pluck(:id)
    assert_equal patient_ids, (JSON.parse(response.body)['linelist'].map { |patient| patient['id'] })

    get :patients, params: { workflow: 'exposure', tab: 'all', order: order, direction: 'desc' }
    patient_ids = user.viewable_patients.where(isolation: false, purged: false).order(last_name: :desc, first_name: :desc).pluck(:id)
    assert_equal patient_ids, (JSON.parse(response.body)['linelist'].map { |patient| patient['id'] })

    sign_out user
  end

  test 'patients pagination' do
    user = create(:public_health_user, jurisdiction: Jurisdiction.where(path: 'USA, State 1').first)
    sign_in user

    entries = 5

    get :patients, params: { workflow: 'exposure', tab: 'all', entries: entries, page: 0 }
    page_0 = JSON.parse(response.body)
    assert_equal entries, page_0['linelist'].size
    assert_not_equal entries, page_0['total']

    get :patients, params: { workflow: 'exposure', tab: 'all', entries: entries, page: 1 }
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

    %i[public_health_user public_health_enroller_user].each do |role|
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

    %i[public_health_user public_health_enroller_user].each do |role|
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
end
