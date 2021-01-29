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
          assert json_response['jurisdiction_paths'].key?(sub_jur.id.to_s)
          assert_equal sub_jur[:path], json_response['jurisdiction_paths'][sub_jur.id.to_s]
        end

        sign_out user
      end
    end
  end

  test 'assigned users for viewable patients' do
    post :assigned_users_for_viewable_patients
    assert_redirected_to(new_user_session_path)

    %i[analyst_user].each do |role|
      user = create(role)
      sign_in user
      post :jurisdiction_paths
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
          post :assigned_users_for_viewable_patients
        end
        assert_includes(error.message, 'query')

        error = assert_raises(ActionController::ParameterMissing) do
          post :assigned_users_for_viewable_patients, params: { query: { scope: '' } }, as: :json
        end
        assert_includes(error.message, 'jurisdiction')

        error = assert_raises(ActionController::ParameterMissing) do
          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: 4 } }, as: :json
        end
        assert_includes(error.message, 'scope')

        post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: 4, scope: 'all', workflow: 'asdf' } }, as: :json
        assert_response :bad_request

        post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: 4, scope: 'all', tab: 'fdsa' } }, as: :json
        assert_response :bad_request

        post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: 4, scope: 'all', workflow: 'exposure', tab: 'reporting' } }, as: :json
        assert_response :bad_request

        post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: 4, scope: 'all', workflow: 'isolation', tab: 'pui' } }, as: :json
        assert_response :bad_request

        sign_out user
      end
    end

    Jurisdiction.where(path: ['USA', 'USA, State 1', 'USA, State 1, County 1']).find_each do |user_jur|
      user = create(:public_health_user, jurisdiction: user_jur)
      sign_in user

      Jurisdiction.all.find_each do |jur|
        %w[all exact].each do |scope|
          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope } }, as: :json
          assert_response :bad_request && next unless user_jur.subtree.include?(jur)

          patients = scope == 'exact' ? jur.immediate_patients.where.not(assigned_user: nil) : jur.all_patients_excluding_purged.where.not(assigned_user: nil)
          assert_equal patients.distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'exposure', tab: 'all' } },
                                                      as: :json
          assert_equal patients.where(isolation: false, purged: false).distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'exposure', tab: 'symptomatic' } },
                                                      as: :json
          assert_equal patients.exposure_symptomatic.distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'exposure', tab: 'non_reporting' } },
                                                      as: :json
          assert_equal patients.exposure_non_reporting.distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'exposure', tab: 'asymptomatic' } },
                                                      as: :json
          assert_equal patients.exposure_asymptomatic.distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'exposure', tab: 'pui' } },
                                                      as: :json

          assert_equal patients.exposure_under_investigation.distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'exposure', tab: 'closed' } },
                                                      as: :json
          assigned_users = patients.where(isolation: false, monitoring: false, purged: false).distinct.pluck(:assigned_user).sort
          assert_equal assigned_users, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'exposure', tab: 'transferred_in' } },
                                                      as: :json
          assigned_users = if scope == 'exact'
                             jur.transferred_in_patients.where(isolation: false,
                                                               jurisdiction: jur.id).where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort
                           else
                             jur.transferred_in_patients.where(isolation: false).where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort
                           end
          assert_equal assigned_users, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'isolation', tab: 'all' } },
                                                      as: :json
          assert_equal patients.where(isolation: true, purged: false).distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'isolation', tab: 'requiring_review' } },
                                                      as: :json
          assert_equal patients.isolation_requiring_review.distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'isolation', tab: 'non_reporting' } },
                                                      as: :json
          assert_equal patients.isolation_non_reporting.distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'isolation', tab: 'reporting' } },
                                                      as: :json
          assert_equal patients.isolation_reporting.distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'isolation', tab: 'closed' } },
                                                      as: :json
          assert_equal patients.where(isolation: true, monitoring: false, purged: false).distinct.pluck(:assigned_user).sort,
                       JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'isolation', tab: 'transferred_in' } },
                                                      as: :json
          assigned_users = if scope == 'exact'
                             jur.transferred_in_patients.where(isolation: true,
                                                               jurisdiction: jur.id).where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort
                           else
                             jur.transferred_in_patients.where(isolation: true).where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort
                           end
          assert_equal assigned_users, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'all', tab: 'all' } },
                                                      as: :json
          assert_equal patients.where(purged: false).distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'all', tab: 'closed' } },
                                                      as: :json
          assert_equal patients.where(monitoring: false, purged: false).distinct.pluck(:assigned_user).sort, JSON.parse(response.body)['assigned_users']

          post :assigned_users_for_viewable_patients, params: { query: { jurisdiction: jur.id, scope: scope, workflow: 'all', tab: 'transferred_in' } },
                                                      as: :json
          assigned_users = if scope == 'exact'
                             jur.transferred_in_patients.where(jurisdiction: jur.id).where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort
                           else
                             jur.transferred_in_patients.where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort
                           end
          assert_equal assigned_users, JSON.parse(response.body)['assigned_users']
        end
      end

      sign_out user
    end
  end
end
