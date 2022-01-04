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

  def edit_user
    # Edit Row Button (below) is an aria-label. Enabling for this test only
    Capybara.enable_aria_label = true
    page.execute_script("$('user-modal').css('transition','none')")

    # The users we are interested in adjusting are on the second page when viewing 25 users/page
    select '50', from: 'Adjust number of records'

    # Edit user with email 'manual_locked_user@example.com'
    tr = find('tr', text: 'manual_locked_user@example.com')
    tr.click_button 'Edit Row Button'

    find("input[name='status']", visible: false)
    assert page.has_field? 'status', type: :hidden, with: 'No longer an employee'

    # Unlock the user with email 'manual_locked_user@example.com'
    find(:xpath, "//label[@for='system-access-input']").click
    assert page.has_no_field? 'status', type: :hidden, with: 'No longer an employee'
    assert page.has_selector?('div', text: 'Inactive')

    find('.modal-footer').click_on('Cancel')

    assert page.has_text? 'auto_locked_user@example.com'

    # Edit user with email 'auto_locked_user@example.com'
    tr = find('tr', text: 'auto_locked_user@example.com')
    tr.click_button 'Edit Row Button'

    find("input[name='status']", visible: false)
    assert page.has_field? 'status', type: :hidden, with: 'Auto-locked by the System'
    assert page.has_text? 'failed login attempts'

    # Unlock the user with email 'auto_locked_user@example.com'
    find(:xpath, "//label[@for='system-access-input']").click
    assert page.has_no_field? 'status', type: :hidden, with: 'Auto-locked by the System'
    assert page.has_no_text? 'failed login attempts'
    assert page.has_selector?('div', text: 'Active')

    # Save the user with email 'auto_locked_user@example.com' after unlocking
    find('.modal-footer').click_on('Save')

    tr = find('tr', text: 'auto_locked_user@example.com')

    # Confirm that the user is Unlocked and status is Active
    assert tr.has_text? 'Unlocked'
    assert tr.has_text? 'Active'
  end

  def search_for_user(query)
    page.execute_script %{ $("#search-input").val("#{query}") }
  end
end
