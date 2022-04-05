# frozen_string_literal: true

require 'test_case'
require_relative '../test_helpers/user_filters_test_helper'

class UserFiltersControllerTest < ActionController::TestCase
  def setup
    @original_max_filters = ADMIN_OPTIONS['max_user_filters']
    @user = create(:user)
    sign_in @user
  end

  def teardown
    ADMIN_OPTIONS['max_user_filters'] = @original_max_filters
  end

  test 'cannot create if the user has too many filters' do
    # Allow only 1 filter to be created
    ADMIN_OPTIONS['max_user_filters'] = 1
    create(:user_filter, user: @user)
    # Allowed to create another filter here, only enforcement is in the controller.
    create(:user_filter, user: @user)
    get :create
    assert_response :bad_request
    assert(JSON.parse(response.body).key?('error'))
  end

  test 'index properly returns a multi-select advanced filter with no options selected' do
    create(:user_filter, user: @user, contents: [UserFiltersTestHelper.multi_select_filter_params].to_json)
    get :index
    assert_response :success
    assert_equal(UserFiltersTestHelper.multi_select_filter_params.to_s, JSON.parse(response.body)[0]['contents'][0].to_s)
  end

  test 'create a multi-select advanced filter with no options selected' do
    post :create, params: UserFiltersTestHelper.multi_select_filter_params
    assert_response :success
    assert_equal(1, @user.user_filters.count)
    parsed_filter = JSON.parse(@user.user_filters.first.contents)
    assert_equal([], parsed_filter[0]['value'])
  end

  test 'create a combination advanced filter' do
    post :create, params: UserFiltersTestHelper.combination_filter_params
    assert_response :success
    assert_equal(1, @user.user_filters.count)
  end
end
