# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'admin_test_helper'

class AdminTest < ApplicationSystemTestCase
  @@admin_test_helper = AdminTestHelper.new(nil)

  test 'view users' do
    @@admin_test_helper.view_users('usa_admin')
    @@admin_test_helper.view_users('state1_admin')
  end

  test 'add users with different jurisdictions and roles' do
    @@admin_test_helper.add_user('usa_admin', 'locals1c1_enroller2@example.com', 'USA, State 1, County 1', 'Enroller', true)
    @@admin_test_helper.add_user('usa_admin', 'state1_enroller2@example.com', 'USA, State 1', 'Enroller', true)
    @@admin_test_helper.add_user('usa_admin', 'usa_enroller2@example.com', 'USA', 'Enroller', true)
    @@admin_test_helper.add_user('usa_admin', 'locals1c2_epi2@example.com', 'USA, State 1, County 2', 'Public Health', true)
    @@admin_test_helper.add_user('usa_admin', 'state1_epi2@example.com', 'USA, State 1', 'Public Health', true)
    @@admin_test_helper.add_user('usa_admin', 'usa_epi2@example.com', 'USA', 'Public Health', true)
    @@admin_test_helper.add_user('usa_admin', 'locals2c3_epi_enroller2@example.com', 'USA, State 2, County 3', 'Public Health Enroller', true)
    @@admin_test_helper.add_user('usa_admin', 'state1_epi_enroller2@example.com', 'USA, State 1', 'Public Health Enroller', true)
    @@admin_test_helper.add_user('usa_admin', 'usa_epi_enroller2@example.com', 'USA', 'Public Health Enroller', true)
    @@admin_test_helper.add_user('usa_admin', 'locals1c1_admin2@example.com', 'USA, State 1, County 1', 'Admin', true)
    @@admin_test_helper.add_user('usa_admin', 'state2_admin2@example.com', 'USA, State 2', 'Admin', true)
    @@admin_test_helper.add_user('usa_admin', 'usa_admin2@example.com', 'USA', 'Admin', true)
    @@admin_test_helper.add_user('usa_admin', 'locals2c4_analyst2@example.com', 'USA, State 2, County 4', 'Analyst', true)
    @@admin_test_helper.add_user('usa_admin', 'state1_analyst2@example.com', 'USA, State 1', 'Analyst', true)
    @@admin_test_helper.add_user('usa_admin', 'usa_analyst2@example.com', 'USA', 'Analyst', true)
  end

  test 'should not add user if close button is clicked' do
    @@admin_test_helper.add_user('usa_admin', 'another_user@example.com', 'USA', 'Enroller', true, false)
  end

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
