# frozen_string_literal: true

require 'test_case'

class AdminControllerTest < ActionController::TestCase
  def setup
    ActionMailer::Base.deliveries.clear
  end

  def teardown; end

  test 'admin authorization' do
    # Shouldn't be able to see admin page without first signing in
    get :users
    assert_redirected_to(new_user_session_path)

    # Only the admin and super user roles should be able to access admin page when signing in
    %i[public_health_enroller_user analyst_user enroller_user public_health_user contact_tracer_user].each do |role|
      user = create(role)
      sign_in user
      get :users
      assert_redirected_to @controller.root_url
      sign_out user
    end
  end

  test 'users param validation' do
    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user

    # Assert >= 0 entries
    get :users, params: { entries: -1, page: 1 }
    assert_response :bad_request

    # Assert >= 0 page number
    get :users, params: { entries: 10, page: -1 }
    assert_response :bad_request

    # Assert orderBy field is not empty and also not expected
    get :users, params: { orderBy: 'test' }
    assert_response :bad_request

    # Assert sortDirection field is not empty and also not expected ("asc", "desc")
    get :users, params: { sortDirection: 'test' }
    assert_response :bad_request

    # Assert that orderBy can't be blank if sortDirection isn't
    get :users, params: { orderBy: '', sortDirection: 'asc' }
    assert_response :bad_request

    # Assert that sortDirection can't be blank if orderBy isn't
    get :users, params: { orderBy: 'id', sortDirection: '' }
    assert_response :bad_request

    sign_out user
  end

  test 'users' do
    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user

    get :users
    parsed_response = JSON.parse(response.body)
    user_rows = parsed_response['user_rows']

    # Assert that all the keys match expected keys and values (on just the first object for speed)
    expected_keys = %i[id email jurisdiction_path role is_locked is_api_enabled is_2fa_enabled num_failed_logins]
    assert user_rows[0].each do |key, value|
      assert expected_keys.include?(key)
      user = User.find_by(user_rows[0].id)
      case key
      when email
        assert_equal(value, user.email)
      when jurisdiction_path
        assert_equal(value, Jurisdiction.find(user.jurisdiction).path)
      when role
        assert_equal(value, user.roles[0])
      when is_locked
        assert_equal(value, !user.locked_at.nil?)
      when is_api_enabled
        assert_equal(value, user.api_enabled)
      when is_2fa_enabled
        assert_equal(value, !user.authy_id.nil?)
      when num_failed_logins
        assert_equal(value, user.failed_attempts)
      end
    end

    # Assert that the total count is correct and that API proxy users were not included
    assert_equal(parsed_response['total'], User.where(is_api_proxy: false).count)

    sign_out user
  end

  test 'user filtering' do
    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user

    # Test filtering by email
    search_query = 'enroller'
    get :users, params: { search: search_query }
    JSON.parse(response.body)['user_rows'].each do |u|
      assert u['email'].include?(search_query)
    end

    # Test filtering by id
    search_query = '1'
    get :users, params: { search: search_query }
    JSON.parse(response.body)['user_rows'].each do |u|
      assert u['id'].to_s.include?(search_query)
    end

    # Test filtering by jurisdiction
    search_query = 'USA, State 1'
    get :users, params: { search: search_query }
    JSON.parse(response.body)['user_rows'].each do |u|
      assert u['jurisdiction_path'].to_s.include?(search_query)
    end

    sign_out user
  end

  test 'user sorting' do
    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user

    # Test sort by ID
    order_by = 'id'

    sort_direction = 'asc'
    get :users, params: { orderBy: order_by, sortDirection: sort_direction }
    ordered_ids = User.where(is_api_proxy: false, jurisdiction_id: user.jurisdiction.subtree_ids).order(id: sort_direction).pluck(:id)
    assert_equal(ordered_ids, (JSON.parse(response.body)['user_rows'].map { |u| u['id'] }))

    sort_direction = 'desc'
    get :users, params: { orderBy: order_by, sortDirection: sort_direction }
    ordered_ids = User.where(is_api_proxy: false, jurisdiction_id: user.jurisdiction.subtree_ids).order(id: sort_direction).pluck(:id)
    assert_equal(ordered_ids, (JSON.parse(response.body)['user_rows'].map { |u| u['id'] }))

    # Test sort by email
    order_by = 'email'

    sort_direction = 'asc'
    get :users, params: { orderBy: order_by, sortDirection: sort_direction }
    ordered_emails = User.where(is_api_proxy: false, jurisdiction_id: user.jurisdiction.subtree_ids).order(email: sort_direction).pluck(:email)
    assert_equal(ordered_emails, (JSON.parse(response.body)['user_rows'].map { |u| u['email'] }))

    sort_direction = 'desc'
    get :users, params: { orderBy: order_by, sortDirection: sort_direction }
    ordered_emails = User.where(is_api_proxy: false, jurisdiction_id: user.jurisdiction.subtree_ids).order(email: sort_direction).pluck(:email)
    assert_equal(ordered_emails, (JSON.parse(response.body)['user_rows'].map { |u| u['email'] }))

    # Test sort by jurisdiction_path
    order_by = 'jurisdiction_path'

    sort_direction = 'asc'
    get :users, params: { orderBy: order_by, sortDirection: sort_direction }
    ordered_paths = User.where(is_api_proxy: false, jurisdiction_id: user.jurisdiction.subtree_ids).joins(:jurisdiction).select(
      'users.id, users.email, users.api_enabled, users.locked_at, users.authy_id, users.failed_attempts, jurisdictions.path '
    ).order(path: sort_direction).pluck(:path)
    assert_equal(ordered_paths, (JSON.parse(response.body)['user_rows'].map { |u| u['jurisdiction_path'] }))

    sort_direction = 'desc'
    get :users, params: { orderBy: order_by, sortDirection: sort_direction }
    ordered_paths = User.where(is_api_proxy: false, jurisdiction_id: user.jurisdiction.subtree_ids).joins(:jurisdiction).select(
      'users.id, users.email, users.api_enabled, users.locked_at, users.authy_id, users.failed_attempts, jurisdictions.path '
    ).order(path: sort_direction).pluck(:path)
    assert_equal(ordered_paths, (JSON.parse(response.body)['user_rows'].map { |u| u['jurisdiction_path'] }))

    # Test sort by num failed logins
    order_by = 'num_failed_logins'

    sort_direction = 'asc'
    get :users, params: { orderBy: order_by, sortDirection: sort_direction }
    ordered_logins = User.where(is_api_proxy: false, jurisdiction_id: user.jurisdiction.subtree_ids)
                         .order(failed_attempts: sort_direction).pluck(:failed_attempts)
    assert_equal(ordered_logins, (JSON.parse(response.body)['user_rows'].map { |u| u['num_failed_logins'] }))

    sort_direction = 'desc'
    get :users, params: { orderBy: order_by, sortDirection: sort_direction }
    ordered_logins = User.where(is_api_proxy: false, jurisdiction_id: user.jurisdiction.subtree_ids)
                         .order(failed_attempts: sort_direction).pluck(:failed_attempts)
    assert_equal(ordered_logins, (JSON.parse(response.body)['user_rows'].map { |u| u['num_failed_logins'] }))

    sign_out user
  end

  test 'user pagination' do
    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user

    # This test assumes there are >5 entries in the test data
    entries = 5

    get :users, params: { entries: entries, page: 0 }
    page_0_response = JSON.parse(response.body)
    assert_equal(entries, page_0_response['user_rows'].size)
    assert_not_equal(entries, page_0_response['total'])

    get :users, params: { entries: entries, page: 1 }
    page_1_response = JSON.parse(response.body)
    assert_not_equal(page_0_response, page_1_response)

    sign_out user
  end

  test 'create user' do
    # Test redirect if not admin user
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user
    post :create_user
    assert_redirected_to @controller.root_url
    sign_out user

    current_user_jur = Jurisdiction.find_by(path: 'USA, State 1')
    user = create(:admin_user, jurisdiction: current_user_jur)
    sign_in user

    # Test email param
    post :create_user, params: { email: 'bad format', jurisdiction: current_user_jur.id,
                                 role_title: 'analyst', is_api_enabled: false }, as: :json
    assert_response :bad_request

    post :create_user, params: { jurisdiction: current_user_jur.id,
                                 role_title: 'analyst', is_api_enabled: false }, as: :json
    assert_response :bad_request

    # Test invalid jurisdiction param
    post :create_user, params: { email: 'test@testing.com', jurisdiction: '',
                                 role_title: 'analyst', is_api_enabled: false }, as: :json
    assert_response :bad_request

    # Test invalid jurisdiction param (out of scope jurisdiction)
    post :create_user, params: { email: 'test@testing.com', jurisdiction: Jurisdiction.find_by(path: 'USA, State 2').id,
                                 role_title: 'analyst', is_api_enabled: false }, as: :json
    assert_response :bad_request

    # Test role param
    post :create_user, params: { email: 'test@testing.com', jurisdiction: current_user_jur.id,
                                 role_title: 'test', is_api_enabled: false }, as: :json
    assert_response :bad_request

    # Test is_api_enabled param
    post :create_user, params: { email: 'test@testing.com', jurisdiction: current_user_jur.id,
                                 role_title: 'analyst', is_api_enabled: 'test' }, as: :json
    assert_response :bad_request

    # Test User is created correctly
    assert_difference 'User.count' do
      post :create_user, params: { email: 'test@testing.com', jurisdiction: current_user_jur.id,
                                   role_title: 'public_health_enroller', is_api_enabled: true }, as: :json
    end
    assert_response :success

    user = User.find_by(email: 'test@testing.com')
    assert_equal(user.jurisdiction, current_user_jur)
    assert_equal(user.api_enabled, true)
    assert_equal(user.role, 'public_health_enroller')
    assert_equal(user.force_password_change, true)

    # Test welcome email is queued
    last_email = ActionMailer::Base.deliveries.last
    assert_equal(last_email.to, ['test@testing.com'])
    assert_equal(last_email.subject, 'Welcome to the Sara Alert system')

    sign_out user
  end

  test 'edit user' do
    # Test redirect if not admin user
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user
    post :edit_user
    assert_redirected_to @controller.root_url
    sign_out user

    current_user_jur = Jurisdiction.find_by(path: 'USA, State 1')
    user = create(:admin_user, jurisdiction: current_user_jur)
    sign_in user

    new_jur = Jurisdiction.find_by(path: 'USA, State 1, County 1')

    # Test id param
    post :edit_user, params: { id: 'test', email: 'bad format', jurisdiction: new_jur.id,
                               role_title: 'analyst', is_api_enabled: false, is_locked: false }, as: :json
    assert_response :bad_request

    # Test email param
    post :edit_user, params: { id: 17, email: 'bad format', jurisdiction: new_jur.id,
                               role_title: 'analyst', is_api_enabled: false, is_locked: false }, as: :json
    assert_response :bad_request

    post :edit_user, params: { id: 17, jurisdiction: new_jur.id, role_title: 'analyst', is_api_enabled: false,
                               is_locked: false }, as: :json
    assert_response :bad_request

    # Test bad jurisdiction param
    post :edit_user, params: { id: 17, email: 'test@testing.com', jurisdiction: '',
                               role_title: 'analyst', is_api_enabled: false, is_locked: false }, as: :json
    assert_response :bad_request

    # Test invalid jurisdiction param (out of scope jurisdiction)
    post :edit_user, params: { id: 17, email: 'test@testing.com', jurisdiction: Jurisdiction.find_by(path: 'USA, State 2').id,
                               role_title: 'analyst', is_api_enabled: false, is_locked: false }, as: :json
    assert_response :bad_request

    # Test role param
    post :edit_user, params: { id: 17, email: 'test@testing.com', jurisdiction: new_jur.id, role_title: 'test',
                               is_api_enabled: false, is_locked: false }, as: :json
    assert_response :bad_request

    # Test is_api_enabled param
    post :edit_user, params: { id: 17, email: 'test@testing.com', jurisdiction: new_jur.id, role_title: 'analyst',
                               is_api_enabled: 'test', is_locked: false }, as: :json
    assert_response :bad_request

    # Test is_locked param
    post :edit_user, params: { id: 17, email: 'test@testing.com', jurisdiction: new_jur.id, role_title: 'analyst',
                               is_api_enabled: false, is_locked: 'test' }, as: :json
    assert_response :bad_request

    # Test User is edited correctly after updating all fields
    assert_no_difference 'User.count' do
      post :edit_user, params: { id: 17, email: 'test@testing.com', jurisdiction: new_jur.id,
                                 role_title: 'public_health_enroller', is_api_enabled: false, is_locked: true }, as: :json
    end
    assert_response :success

    # NOTE: Patient with ID 17 must be within USA, State 1 hierarchy for this test to pass
    user = User.find_by(id: 17)
    assert_equal(user.jurisdiction, new_jur)
    assert_equal(user.api_enabled, false)
    assert_equal(user.role, 'public_health_enroller')
    assert user.locked_at?

    sign_out user
  end

  test 'reset 2fa' do
    # Test redirect if not admin user
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user
    post :reset_2fa
    assert_redirected_to @controller.root_url
    sign_out user

    # Test for bad request if user's jurisdiction is not underneath the current user's jurisdiction
    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA, State 1'))
    sign_in user

    post :reset_2fa, params: { ids: [10, 3] }, as: :json
    assert_response :bad_request

    sign_out user

    # Create USA user
    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user

    # Test for ids param validation
    post :reset_2fa, params: { ids: 'test' }, as: :json
    assert_response :bad_request

    # Test 2FA is reset for all users with passed in ids
    user_ids = [1, 2, 3]
    assert_no_difference 'User.count' do
      post :reset_2fa, params: { ids: user_ids }, as: :json
    end
    assert_response :success

    User.where(id: user_ids).each do |u|
      assert u.authy_id.nil?
      assert !u.authy_enabled
    end

    sign_out user
  end

  test 'reset password' do
    # Test redirect if not admin user
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user
    post :reset_password
    assert_redirected_to @controller.root_url
    sign_out user

    # Test for bad request if user's jurisdiction is not underneath the current user's jurisdiction
    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA, State 1'))
    sign_in user

    post :reset_password, params: { ids: [10, 3] }, as: :json
    assert_response :bad_request

    sign_out user

    # Create USA user
    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user

    # Test for ids param validation
    post :reset_password, params: { ids: 'test' }, as: :json
    assert_response :bad_request

    # Test password is reset for all users with passed in ids
    user_ids = [1, 2, 3]
    assert_no_difference 'User.count' do
      post :reset_password, params: { ids: user_ids }, as: :json
    end
    assert_response :success

    # Test welcome emails were sent for all three users
    delivered_emails = ActionMailer::Base.deliveries.sort_by(&:to)
    users = User.where(id: user_ids).sort_by(&:email)
    assert_equal(users.length, delivered_emails.length)
    users.each_with_index do |u, index|
      assert u.force_password_change
      # Test that the welcome email is queued
      email = delivered_emails[index]
      assert_equal(email.to, [u.email])
      assert_equal(email.subject, 'Welcome to the Sara Alert system')
    end

    sign_out user
  end

  test 'email_all' do
    # Test redirect if not admin user
    user = create(:public_health_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user
    post :email_all
    assert_redirected_to @controller.root_url
    sign_out user

    user = create(:admin_user, jurisdiction: Jurisdiction.find_by(path: 'USA'))
    sign_in user

    # Test for comment param validation
    post :email_all, params: { comment: ' ' }, as: :json
    assert_response :bad_request

    # Lock the first user
    User.first.update!(locked_at: Time.now)

    # Test email is sent for all unlocked users
    assert_no_difference 'User.count' do
      post :email_all, params: { comment: 'Hello!' }, as: :json
    end
    assert_response :success

    delivered_emails = ActionMailer::Base.deliveries.sort_by(&:to)
    users = User.where(locked_at: nil).sort_by(&:email)

    assert_equal(delivered_emails.length, users.length)
    users.each_with_index do |u, index|
      email = delivered_emails[index]
      assert_equal(email.to, [u.email])
      assert_equal(email.subject, 'Message from the Sara Alert system')
    end

    sign_out user
  end
end
