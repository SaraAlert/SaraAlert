# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCaseAdmin'

require_relative 'admin_test_helper'

class AdminTest < ApplicationSystemTestCase
  @@admin_test_helper = AdminTestHelper.new(nil)

  test 'view users' do
    @@admin_test_helper.view_users('usa_admin')
    @@admin_test_helper.view_users('state1_admin')
  end

  # test 'add users with different jurisdictions and roles' do
  #   users = [
  #     { label: 'usa_admin', email: 'locals1c1_enroller2@example.com', jurisdiction: 'USA, State 1, County 1', role: 'Enroller', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'state1_enroller2@example.com', jurisdiction: 'USA, State 1', role: 'Enroller', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'usa_enroller2@example.com', jurisdiction: 'USA', role: 'Enroller', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'locals1c2_epi2@example.com', jurisdiction: 'USA, State 1, County 2', role: 'Public Health', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'state1_epi2@example.com', jurisdiction: 'USA, State 1', role: 'Public Health', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'usa_epi2@example.com', jurisdiction: 'USA', role: 'Public Health', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'state1_epi_enroller2@example.com', jurisdiction: 'USA, State 1', role: 'Public Health Enroller', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'usa_epi_enroller2@example.com', jurisdiction: 'USA', role: 'Public Health Enroller', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'locals1c1_admin2@example.com', jurisdiction: 'USA, State 1, County 1', role: 'Admin', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'state2_admin2@example.com', jurisdiction: 'USA, State 2', role: 'Admin', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'usa_admin2@example.com', jurisdiction: 'USA', role: 'Admin', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'locals2c4_analyst2@example.com', jurisdiction: 'USA, State 2, County 4', role: 'Analyst', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'state1_analyst2@example.com', jurisdiction: 'USA, State 1', role: 'Analyst', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'usa_analyst2@example.com', jurisdiction: 'USA', role: 'Analyst', is_api_enabled: true },
  #     { label: 'usa_admin', email: 'locals2c3_epi_enroller2@example.com', jurisdiction: 'USA, State 2, County 3',
  #       role: 'Public Health Enroller', is_api_enabled: true }
  #   ]

  #   users.each do |user_data|
  #     @@admin_test_helper.add_user(user_data)
  #   end
  # end

  # test 'should not add user if close button is clicked' do
  #   user_data = { label: 'usa_admin', email: 'another_user@example.com', jurisdiction: 'USA', role: 'Enroller', is_api_enabled: true }
  #   @@admin_test_helper.add_user(user_data, false)
  # end

  # test 'edit users with different jurisdictions and roles' do
  # end

  # test 'should not edit user if close button is clicked' do
  # end

  # test 'should display error message if there was a problem editing the user' do
  # end

  # test 'reset 2fa of selected users' do
  # end

  # test 'reset passwords of selected users' do
  # end

  # test 'send email to selected users' do
  # end

  # test 'export user data' do
  # end

  # test 'send email to all users' do
  # end
end
