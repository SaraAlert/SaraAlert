# frozen_string_literal: true

require 'test_case'

class JurisdictionsControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  test 'jurisdiction paths' do
    get :jurisdiction_paths
    assert_redirected_to(new_user_session_path)

    %i[analyst_user].each do |role|
      user = create(role)
      sign_in user
      get :jurisdiction_paths
      assert_response :unauthorized
      sign_out user
    end

    %i[enroller_user public_health_user public_health_enroller_user contact_tracer_user super_user].each do |role|
      user = create(role)

      Jurisdiction.where(path: ['USA', 'USA, State 1', 'USA, State 1, County 1']).find_each do |user_jur|
        user.update(jurisdiction: user_jur)
        sign_in user

        get :jurisdiction_paths
        json_response = JSON.parse(response.body)

        assert_equal user_jur.subtree.size, json_response['jurisdiction_paths'].size
        user_jur.subtree.each do |sub_jur|
          assert json_response['jurisdiction_paths'].key?(sub_jur[:id].to_s)
          assert_equal sub_jur[:path], json_response['jurisdiction_paths'][sub_jur[:id].to_s]
        end

        sign_out user
      end
    end
  end

  test 'assigned users for viewable patients' do
    get :assigned_users_for_viewable_patients
    assert_redirected_to(new_user_session_path)

    %i[analyst_user].each do |role|
      user = create(role)
      sign_in user
      get :jurisdiction_paths
      assert_response :unauthorized
      sign_out user
    end

    %i[enroller_user public_health_user public_health_enroller_user contact_tracer_user super_user].each do |role|
      user = create(role)

      jurs = Jurisdiction.where(path: ['USA', 'USA, State 1', 'USA, State 1, County 1'])
      jurs.find_each do |user_jur|
        user.update(jurisdiction: user_jur)
        sign_in user

        error = assert_raises(ActionController::ParameterMissing) do
          get :assigned_users_for_viewable_patients
        end
        assert_includes(error.message, 'jurisdiction_id')

        error = assert_raises(ActionController::ParameterMissing) do
          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: 4 }
        end
        assert_includes(error.message, 'scope')

        get :assigned_users_for_viewable_patients, params: { jurisdiction_id: 4, scope: 'all', workflow: 'asdf' }
        assert_response :bad_request

        get :assigned_users_for_viewable_patients, params: { jurisdiction_id: 4, scope: 'all', tab: 'all' }
        assert_response :bad_request

        get :assigned_users_for_viewable_patients, params: { jurisdiction_id: 4, scope: 'all', workflow: 'exposure', tab: 'requiring_review' }
        assert_response :bad_request

        get :assigned_users_for_viewable_patients, params: { jurisdiction_id: 4, scope: 'all', workflow: 'isolation', tab: 'pui' }
        assert_response :bad_request

        sign_out user
      end
    end

    user = create(:public_health_user)

    jurs = Jurisdiction.where(path: ['USA', 'USA, State 1', 'USA, State 1, County 1'])
    jurs.find_each do |user_jur|
      user.update(jurisdiction: user_jur)
      sign_in user

      jurs.find_each do |jur|
        %w[all exact].each do |scope|
          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope }
          assert_response :bad_request && next unless user_jur.subtree.include?(jur)

          patients = scope == 'all' ? jur.all_patients.where.not(assigned_user: nil) : jur.immediate_patients.where.not(assigned_user: nil)
          assert_equal patients.distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'exposure', tab: 'all' }
          assert_equal patients.where(isolation: false, purged: false).distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'exposure', tab: 'symptomatic' }
          assert_equal patients.exposure_symptomatic.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'exposure', tab: 'non_reporting' }
          assert_equal patients.exposure_non_reporting.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'exposure', tab: 'asymptomatic' }
          assert_equal patients.exposure_asymptomatic.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'exposure', tab: 'pui' }
          assert_equal patients.exposure_under_investigation.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'exposure', tab: 'closed' }
          assert_equal patients.where(isolation: false, monitoring: false, purged: false).pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'exposure', tab: 'transferred_in' }
          assigned_users = if scope == 'all'
                             jur.transferred_in_patients.where(isolation: false).pluck(:assigned_user).sort
                           else
                             jur.transferred_in_patients.where(isolation: false, jurisdiction_id: jur[:id]).pluck(:assigned_user).sort
                           end
          assert_equal assigned_users, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'isolation', tab: 'all' }
          assert_equal patients.where(isolation: true, purged: false).distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'isolation', tab: 'requiring_review' }
          assert_equal patients.isolation_requiring_review.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'isolation', tab: 'non_reporting' }
          assert_equal patients.isolation_non_reporting.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'isolation', tab: 'reporting' }
          assert_equal patients.isolation_reporting.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'isolation', tab: 'closed' }
          assert_equal patients.where(isolation: true, monitoring: false, purged: false).pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_user']

          get :assigned_users_for_viewable_patients, params: { jurisdiction_id: jur[:id], scope: scope, workflow: 'isolation', tab: 'transferred_in' }
          assigned_users = if scope == 'all'
                             jur.transferred_in_patients.where(isolation: true).pluck(:assigned_user).sort
                           else
                             jur.transferred_in_patients.where(isolation: true, jurisdiction_id: jur[:id]).pluck(:assigned_user).sort
                           end
          assert_equal assigned_users, JSON.parse(response.body)['assigned_user']
        end
      end

      sign_out user
    end
  end
end
