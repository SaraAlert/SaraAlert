# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../../../lib/system_test_utils'

class AdminDashboardVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_user(user, should_exist: true)
    Capybara.using_wait_time(8) do
      if should_exist
        assert page.has_content?(user.email), @@system_test_utils.get_err_msg('User info', 'email', user.email)
        verify_lock_status(user.email, !user.locked_at.nil?)
      else
        assert page.has_no_content?(user.email), @@system_test_utils.get_err_msg('User info', 'email', 'nonexistent')
      end
    end
  end

  def verify_add_user(user_data, submit: true)
    if submit
      assert page.has_content?(user_data[:email]), @@system_test_utils.get_err_msg('New user info', 'email', user_data[:email])
      assert page.has_content?(user_data[:jurisdiction]), @@system_test_utils.get_err_msg('New user info', 'jurisdiction', user_data[:jurisdiction])
      assert page.has_content?(user_data[:role]), @@system_test_utils.get_err_msg('New user info', 'role', user_data[:role])
    else
      assert page.has_no_content?(user_data[:email]), @@system_test_utils.get_err_msg('Add user', 'user', 'non-existent')
    end
  end

  def verify_user_field(field, value)
    assert page.find('tbody').has_content?(value), @@system_test_utils.get_err_msg('User info', field, value) unless value.nil?
  end

  def verify_lock_status(email, locked)
    if locked
      assert page.has_content?('Locked'), @@system_test_utils.get_err_msg('User info', 'status', 'Locked')
      assert_not_nil User.where(email: email).first.locked_at, @@system_test_utils.get_err_msg('Lock user', 'locked_at', 'not nil')
    else
      assert page.has_content?('Unlocked'), @@system_test_utils.get_err_msg('User info', 'status', 'Unlocked')
      assert_nil User.where(email: email).first.locked_at, @@system_test_utils.get_err_msg('Lock user', 'locked_at', 'nil')
    end
  end

  def verify_reset_user_password(email)
    assert User.where(email: email).first.force_password_change, @@system_test_utils.get_err_msg('Reset user password', 'force_password_change', 'true')
  end

  def verify_enable_api(email, enable)
    assert page.has_content?(enable ? 'Disable' : 'Enable'), @@system_test_utils.get_err_msg('Enable API', 'button on page', enable ? 'Disable' : 'Enable')

    err_msg = @@system_test_utils.get_err_msg('Enable API', 'value in db', User.where(email: email).first.api_enabled)
    assert_equal enable, User.where(email: email).first.api_enabled, err_msg
  end
end
