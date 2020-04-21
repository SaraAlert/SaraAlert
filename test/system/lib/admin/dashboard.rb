# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard_verifier'
require_relative '../system_test_utils'

class AdminDashboard < ApplicationSystemTestCase
  @@admin_dashboard_verifier = AdminDashboardVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def add_user(email, jurisdiction, role, submit=true)
    click_on 'Add User'
    fill_in 'Email', with: email
    select jurisdiction, from: 'Jurisdiction'
    select role, from: 'Role'
    if submit
      find('.modal-footer').click_on('Add User')
    else
      find('.modal-footer').click_on('Close')
    end
  end

  def lock_user(email)
    search_for_user(email)
    click_on 'Lock'
    @@admin_dashboard_verifier.verify_lock_status(email, true)
  end

  def unlock_user(email)
    search_for_user(email)
    click_on 'Unlock'
    @@admin_dashboard_verifier.verify_lock_status(email, false)
  end

  def reset_user_password(email)
    search_for_user(email)
    click_on 'Reset Password and Send Email'
    sleep(1) # Added sleep to prevent reoccurring race condition when saving user
    @@admin_dashboard_verifier.verify_reset_user_password(email)
  end

  def search_for_user(query)
    fill_in 'Search', with: query
  end
end