# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard/dashboard'
require_relative 'dashboard/dashboard_verifier'
require_relative '../../lib/system_test_utils'

class AdminTestHelper < ApplicationSystemTestCase
  @@admin_dashboard = AdminDashboard.new(nil)
  @@admin_dashboard_verifier = AdminDashboardVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def view_users(user_label)
    jurisdiction_id = @@system_test_utils.login(user_label)
    User.where(jurisdiction_id: Jurisdiction.find(jurisdiction_id).subtree_ids).each do |user|
      @@admin_dashboard.search_for_user(user.email)
      @@admin_dashboard_verifier.verify_user(user, should_exist: true)
    end
    User.where.not(jurisdiction_id: Jurisdiction.find(jurisdiction_id).subtree_ids).each do |user|
      @@admin_dashboard.search_for_user(user.email)
      @@admin_dashboard_verifier.verify_user(user, should_exist: false)
    end
    @@system_test_utils.logout
  end

  def add_user(user_data, submit: true)
    @@system_test_utils.login(user_data[:label])
    Capybara.using_wait_time(4) do
      @@admin_dashboard.add_user(user_data, submit: submit)
      @@admin_dashboard.search_for_user(user_data[:email])
      @@admin_dashboard_verifier.verify_add_user(user_data, submit: submit)
    end
    @@system_test_utils.logout
  end

  def add_existing_user(user_label, email, jurisdiction, role, is_api_enabled)
    @@system_test_utils.login(user_label)
    @@admin_dashboard.add_user(email, jurisdiction, role, is_api_enabled)
    assert_equal('User already exists', page.driver.browser.switch_to.alert.text)
    page.driver.browser.switch_to.alert.dismiss
    @@system_test_utils.logout
  end

  def edit_user(user_label, id)
    # TODO: implement
  end

  def select_user(user_label, id)
    # TODO: implement
  end

  def lock_user(user_label, email)
    @@system_test_utils.login(user_label)
    @@admin_dashboard.lock_user(email)
    @@admin_dashboard.unlock_user(email)
    @@system_test_utils.logout
  end

  def reset_user_password(user_label, email)
    @@system_test_utils.login(user_label)
    @@admin_dashboard.reset_user_password(email)
    @@system_test_utils.logout
  end

  def enable_api(user_label, email, enable)
    @@system_test_utils.login(user_label)
    @@admin_dashboard.enable_api(email, enable)
    @@system_test_utils.logout
  end
end
