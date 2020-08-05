# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard_verifier'
require_relative '../../../lib/system_test_utils'

class AdminDashboard < ApplicationSystemTestCase
  @@admin_dashboard_verifier = AdminDashboardVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def add_user(email, jurisdiction, role, isAPIEnabled, submit = true)
    click_on 'Add User'
    fill_in 'email', with: email
    select jurisdiction, from: 'jurisdiction'
    select role, from: 'role'

    if isAPIEnabled
      find('label[for="access-input"]').click
    end
      
    if submit
      find('.modal-footer').click_on('Save')
    else
      find('.modal-footer').click_on('Close')
    end
  end

  def search_for_user(query)
    fill_in 'search', with: query
  end
end
