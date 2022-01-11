# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../../../lib/system_test_utils'

class AdminDashboardVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)
  # 'Adjust number of records' (below) is an aria-label. Enabling for this test only
  Capybara.enable_aria_label = true

  def verify_user(user, should_exist: true)
    Capybara.using_wait_time(8) do
      assert page.has_content? 'Email'
      select '50', from: 'Adjust number of records'
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
    find('#admin-table-all-filter-btn').click
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

  def verify_unlock_locked_user(email, auto_locked, is_active, status, auto_lock_message)
    find("input[name='status']", visible: false)

    assert page.has_field? 'status', type: :hidden, with: status
    assert page.has_text? auto_lock_message if auto_locked

    # Unlock the user
    find(:xpath, "//label[@for='system-access-input']").click

    assert page.has_no_field? 'status', type: :hidden, with: status
    assert page.has_no_text? auto_lock_message if auto_locked

    assert page.has_selector? 'div', text: 'Active' if is_active
    assert page.has_selector? 'div', text: 'Inactive' unless is_active

    # Save the user after unlocking
    find('.modal-footer').click_on('Save')

    tr = find('tr', text: email)

    # Confirm that the user is Unlocked and status is correct
    assert tr.has_text? 'Unlocked'
    assert tr.has_text? 'Active' if is_active
    assert tr.has_text? 'Inactive' unless is_active
  end

  def verify_lock_unlocked_user(email, is_active)
    assert page.has_no_field? 'status', type: :hidden
    assert page.has_selector? 'div', text: 'Active' if is_active
    assert page.has_selector? 'div', text: 'Inactive' unless is_active

    # Lock the user
    find(:xpath, "//label[@for='system-access-input']").click

    # NOTE: This doesn't seem to work and may not even be a worthwhile endeavor.
    # There is no way to 'select' with Capybara when using React
    # page.execute_script("(document.getElementsByName('status')[0]).value = '#{status}'")
    # assert page.has_field? 'status', type: :hidden, with: status

    # Save the user with after locking
    find('.modal-footer').click_on('Save')

    tr = find('tr', text: email)

    # Confirm that the user is Locked
    assert tr.has_text? 'Locked'
  end
end
