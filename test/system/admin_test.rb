# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'lib/system_test_utils'

class AdminTest < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'add users with different jurisdictions and roles' do
    verify_add_user('locals1c1_enroller2@example.com', 'USA, State 1, County 1', 'enroller')
    verify_add_user('state1_enroller2@example.com', 'USA, State 1', 'enroller')
    verify_add_user('usa_enroller2@example.com', 'USA', 'enroller')
    verify_add_user('locals1c1_epi2@example.com', 'USA, State 1, County 1', 'public_health')
    verify_add_user('state1_epi2@example.com', 'USA, State 1', 'public_health')
    verify_add_user('usa_epi2@example.com', 'USA', 'public_health')
    verify_add_user('locals1c1_epi_enroller2@example.com', 'USA, State 1, County 1', 'public_health_enroller')
    verify_add_user('state1_epi_enroller2@example.com', 'USA, State 1', 'public_health_enroller')
    verify_add_user('usa_epi_enroller2@example.com', 'USA', 'public_health_enroller')
    verify_add_user('locals1c1_adminr2@example.com', 'USA, State 1, County 1', 'admin')
    verify_add_user('state1_admin2@example.com', 'USA, State 1', 'admin')
    verify_add_user('usa_admin2@example.com', 'USA', 'admin')
    verify_add_user('locals1c1_analyst2@example.com', 'USA, State 1, County 1', 'analyst')
    verify_add_user('state1_analyst2@example.com', 'USA, State 1', 'analyst')
    verify_add_user('usa_analyst2@example.com', 'USA', 'analyst')
  end

  test 'should not add user if close button is clicked' do
    @@system_test_utils.login('admin1')
    add_user_and_cancel('user@example.com', 'USA', 'enroller')
  end

  test 'should display error message if user is added with email of an existing user' do
    @@system_test_utils.login('admin1')
    add_user('locals1c1_enroller@example.com', 'USA, State 1, County 1', 'enroller')
    assert_equal('User already exists', page.driver.browser.switch_to.alert.text)
  end

  def verify_add_user(email, jurisdiction, role)
    @@system_test_utils.login('admin1')
    add_user(email, jurisdiction, role)
    assert_selector 'td', text: email
    assert_selector 'td', text: jurisdiction
    assert_selector 'td', text: role
    @@system_test_utils.logout
    # @@system_test_utils.login_with_custom_password(email, '123456ab') # verify login with generated password
  end

  def add_user(email, jurisdiction, role)
    click_on 'Add User'
    populate_user_info(email, jurisdiction, role)
    find('.modal-footer').click_on('Add User')
  end

  def add_user_and_cancel(email, jurisdiction, role)
    click_on 'Add User'
    populate_user_info(email, jurisdiction, role)
    find('.modal-footer').click_on('Close')
    refute_selector 'td', text: email
  end

  def populate_user_info(email, jurisdiction, role)
    fill_in 'Email', with: email
    select jurisdiction, from: 'Jurisdiction'
    select role, from: 'Role'
  end
end
