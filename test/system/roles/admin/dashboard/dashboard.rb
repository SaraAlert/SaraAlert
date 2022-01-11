# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard_verifier'
require_relative '../../../lib/system_test_utils'

class AdminDashboard < ApplicationSystemTestCase
  @@admin_dashboard_verifier = AdminDashboardVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def add_user(user_data, submit: true)
    # Remove fade animation from Bootstrap modal
    # NOTE: This can apparently affect Capybara's fill_in functionality and more
    page.execute_script("$('user-modal').css('transition','none')")

    click_on 'Add User'
    fill_in 'email', with: user_data[:email]
    select user_data[:jurisdiction], from: 'jurisdiction'
    select user_data[:role], from: 'role'

    find('label[for="access-input"]').click if user_data[:is_api_enabled]

    if submit
      find('.modal-footer').click_on('Save')
    else
      find('.modal-footer').click_on('Close')
    end
  end

  def edit_user(email, is_locked, auto_locked, is_active, status, auto_lock_message)
    # Edit Row Button (below) is an aria-label. Enabling for this test only
    Capybara.enable_aria_label = true
    page.execute_script("$('user-modal').css('transition','none')")

    # The users we are interested in adjusting are on the second page when viewing 25 users/page
    select '50', from: 'Adjust number of records'
    assert page.has_text? email

    # Edit user by email
    tr = find('tr', text: email)
    tr.click_button 'Edit Row Button'

    if is_locked
      @@admin_dashboard_verifier.verify_unlock_locked_user(email, auto_locked, is_active, status, auto_lock_message)
    else
      @@admin_dashboard_verifier.verify_lock_unlocked_user(email, is_active)
    end
  end

  def search_for_user(query)
    page.execute_script %{ $("#search-input").val("#{query}") }
  end
end
