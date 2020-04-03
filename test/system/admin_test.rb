# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'lib/admin/helper'
require_relative 'lib/system_test_utils'

class AdminTest < ApplicationSystemTestCase
  @@admin_helper = AdminHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'view users' do
    @@admin_helper.view_users('admin1')
  end

  test 'add users with different jurisdictions and roles' do
    @@admin_helper.add_user('admin1', 'locals1c1_enroller2@example.com', 'USA,State 1,County 1', 'enroller')
    @@admin_helper.add_user('admin1', 'state1_enroller2@example.com', 'USA,State 1', 'enroller')
    @@admin_helper.add_user('admin1', 'usa_enroller2@example.com', 'USA', 'enroller')
    @@admin_helper.add_user('admin1', 'locals1c2_epi2@example.com', 'USA,State 1,County 2', 'public_health')
    @@admin_helper.add_user('admin1', 'state1_epi2@example.com', 'USA,State 1', 'public_health')
    @@admin_helper.add_user('admin1', 'usa_epi2@example.com', 'USA', 'public_health')
    @@admin_helper.add_user('admin1', 'locals2c3_epi_enroller2@example.com', 'USA,State 2,County 3', 'public_health_enroller')
    @@admin_helper.add_user('admin1', 'state1_epi_enroller2@example.com', 'USA,State 1', 'public_health_enroller')
    @@admin_helper.add_user('admin1', 'usa_epi_enroller2@example.com', 'USA', 'public_health_enroller')
    @@admin_helper.add_user('admin1', 'locals1c1_admin2@example.com', 'USA,State 1,County 1', 'admin')
    @@admin_helper.add_user('admin1', 'state2_admin2@example.com', 'USA,State 2', 'admin')
    @@admin_helper.add_user('admin1', 'usa_admin2@example.com', 'USA', 'admin')
    @@admin_helper.add_user('admin1', 'locals2c4_analyst2@example.com', 'USA,State 2,County 4', 'analyst')
    @@admin_helper.add_user('admin1', 'state1_analyst2@example.com', 'USA,State 1', 'analyst')
    @@admin_helper.add_user('admin1', 'usa_analyst2@example.com', 'USA', 'analyst')
  end

  test 'should not add user if close button is clicked' do
    @@admin_helper.add_user('admin1', 'another_user@example.com', 'USA', 'enroller', false)
  end

  test 'should display error message if user is added with email of an existing user' do
    @@admin_helper.add_existing_user('admin1', 'locals1c1_enroller@example.com', 'USA,State 1,County 1', 'enroller')
  end

  test 'lock user' do
    @@admin_helper.lock_user('admin1', 'state1_epi@example.com')
  end

  test 'reset user password' do
    @@admin_helper.reset_user_password('admin1', 'locals1c1_epi@example.com')
  end
end
