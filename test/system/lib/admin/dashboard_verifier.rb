# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../system_test_utils'

class AdminDashboardVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_user(user)
    assert page.has_content?(user.failed_attempts), @@system_test_utils.get_err_msg('User info', 'failed login attempts', user.failed_attempts)
    verify_lock_status(user.email, !user.locked_at.nil?)
  end
  
  def verify_add_user(email, jurisdiction, role, submit=true)
    if submit
      assert page.has_content?(email), @@system_test_utils.get_err_msg('New user info', 'email', email)
      assert page.has_content?(jurisdiction), @@system_test_utils.get_err_msg('New user info', 'jurisdiction', jurisdiction)
      assert page.has_content?(role), @@system_test_utils.get_err_msg('New user info', 'role', role)
      assert page.has_content?('0'), @@system_test_utils.get_err_msg('New user info', 'failed login attempts', '0')
      assert page.has_content?('Unlocked'), @@system_test_utils.get_err_msg('New user info', 'status', 'Unlocked')
      assert page.has_content?('Lock'), @@system_test_utils.get_err_msg('New user info', 'lock/unlock button', 'Lock')
    else
      assert page.has_no_content?(email), @@system_test_utils.get_err_msg('Add user', 'user', 'non-existent')
    end
  end

  def verify_lock_status(email, locked)
    if locked
      assert page.has_content?('Locked'), @@system_test_utils.get_err_msg('User info', 'status', 'Locked')
      assert page.has_content?('Unlock'), @@system_test_utils.get_err_msg('User info', 'lock/unlock button', 'Unlock')
      assert_not_nil User.where(email: email).first.locked_at, @@system_test_utils.get_err_msg('Lock user', 'locked_at', 'not nil')
    else
      assert page.has_content?('Unlocked'), @@system_test_utils.get_err_msg('User info', 'status', 'Unlocked')
      assert page.has_content?('Lock'), @@system_test_utils.get_err_msg('User info', 'lock/unlock button', 'Lock')
      assert_nil User.where(email: email).first.locked_at, @@system_test_utils.get_err_msg('Lock user', 'locked_at', 'nil')
    end
  end

  def verify_reset_user_password(email)
    assert User.where(email: email).first.force_password_change, @@system_test_utils.get_err_msg('Reset user password', 'force_password_change', 'true')
  end
end