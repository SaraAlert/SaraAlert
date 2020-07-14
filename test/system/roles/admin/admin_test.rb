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

  test 'add users with different jurisdictions and roles' do
    @@admin_test_helper.add_user('usa_admin', 'locals1c1_enroller2@example.com', 'USA, State 1, County 1', 'enroller')
    @@admin_test_helper.add_user('usa_admin', 'state1_enroller2@example.com', 'USA, State 1', 'enroller')
    @@admin_test_helper.add_user('usa_admin', 'usa_enroller2@example.com', 'USA', 'enroller')
    @@admin_test_helper.add_user('usa_admin', 'locals1c2_epi2@example.com', 'USA, State 1, County 2', 'public_health')
    @@admin_test_helper.add_user('usa_admin', 'state1_epi2@example.com', 'USA, State 1', 'public_health')
    @@admin_test_helper.add_user('usa_admin', 'usa_epi2@example.com', 'USA', 'public_health')
    @@admin_test_helper.add_user('usa_admin', 'locals2c3_epi_enroller2@example.com', 'USA, State 2, County 3', 'public_health_enroller')
    @@admin_test_helper.add_user('usa_admin', 'state1_epi_enroller2@example.com', 'USA, State 1', 'public_health_enroller')
    @@admin_test_helper.add_user('usa_admin', 'usa_epi_enroller2@example.com', 'USA', 'public_health_enroller')
    @@admin_test_helper.add_user('usa_admin', 'locals1c1_admin2@example.com', 'USA, State 1, County 1', 'admin')
    @@admin_test_helper.add_user('usa_admin', 'state2_admin2@example.com', 'USA, State 2', 'admin')
    @@admin_test_helper.add_user('usa_admin', 'usa_admin2@example.com', 'USA', 'admin')
    @@admin_test_helper.add_user('usa_admin', 'locals2c4_analyst2@example.com', 'USA, State 2, County 4', 'analyst')
    @@admin_test_helper.add_user('usa_admin', 'state1_analyst2@example.com', 'USA, State 1', 'analyst')
    @@admin_test_helper.add_user('usa_admin', 'usa_analyst2@example.com', 'USA', 'analyst')
  end

  test 'should not add user if close button is clicked' do
    @@admin_test_helper.add_user('usa_admin', 'another_user@example.com', 'USA', 'enroller', false)
  end

  test 'should display error message if user is added with email of an existing user' do
    @@admin_test_helper.add_existing_user('usa_admin', 'locals1c1_enroller@example.com', 'USA, State 1, County 1', 'enroller')
  end

  test 'lock user' do
    @@admin_test_helper.lock_user('usa_admin', 'locals2c3_epi@example.com')
    @@admin_test_helper.lock_user('state1_admin', 'state1_epi_enroller@example.com')
  end

  test 'reset user password' do
    @@admin_test_helper.reset_user_password('usa_admin', 'state2_epi@example.com')
    @@admin_test_helper.reset_user_password('state1_admin', 'locals1c1_enroller@example.com')
  end

  test 'enable api' do
    @@admin_test_helper.enable_api('usa_admin', 'locals1c2_epi@example.com', true)
    @@admin_test_helper.enable_api('state1_admin', 'state1_enroller@example.com', true)
  end

  test 'disable api' do
    @@admin_test_helper.enable_api('usa_admin', 'state1_epi_enroller@example.com', false)
  end
end
