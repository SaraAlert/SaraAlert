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

  def search_for_user(query)
    page.execute_script %{ $("#search-input").val("#{query}") }
  end
end
