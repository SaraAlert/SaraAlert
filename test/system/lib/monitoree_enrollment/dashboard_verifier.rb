# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'info_page_verifier'
require_relative '../system_test_utils'

class MonitoreeEnrollmentDashboardVerifier < ApplicationSystemTestCase
  @@monitoree_enrollment_info_page_verifier = MonitoreeEnrollmentInfoPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_monitoree_info_on_dashboard(monitoree)
    displayed_name = search_for_monitoree(monitoree)
    click_on displayed_name
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree)
    @@system_test_utils.return_to_dashboard
  end

  def verify_monitoree_info_as_group_member_on_dashboard(existing_monitoree, new_monitoree)
    displayed_name = search_for_monitoree(new_monitoree)
    click_on displayed_name
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info_as_group_member(existing_monitoree, new_monitoree)
    click_on 'Click here to view that monitoree'
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree)
    @@system_test_utils.return_to_dashboard
  end

  def verify_monitoree_info_not_on_dashboard(monitoree)
    displayed_name = @@system_test_utils.get_dashboard_display_name(monitoree)
    displayed_birthday = @@system_test_utils.format_date(monitoree['identification']['date_of_birth'])
    search_and_verify_nonexistence(monitoree['identification']['first_name'] + ' ' + monitoree['identification']['last_name'] + ' ' + displayed_birthday)
  end

  def search_for_monitoree(monitoree)
    displayed_name = @@system_test_utils.get_dashboard_display_name(monitoree)
    displayed_birthday = @@system_test_utils.format_date(monitoree['identification']['date_of_birth'])
    search_and_verify_existence(monitoree['identification']['first_name'], displayed_name, displayed_birthday)
    search_and_verify_existence(monitoree['identification']['last_name'], displayed_name, displayed_birthday)
    search_and_verify_existence(displayed_birthday, displayed_name, displayed_birthday)
    displayed_name
  end

  def search_and_verify_existence(query, displayed_name, displayed_birthday)
    go_to_correct_tab
    fill_in 'Search:', with: query
    assert_selector 'td', text: displayed_name
    assert_selector 'td', text: displayed_birthday
  end

  def search_and_verify_nonexistence(query)
    go_to_correct_tab
    fill_in 'Search:', with: query
    assert_selector 'td', text: 'No data available in table'
  end

  def go_to_correct_tab
    click_on 'Asymptomatic' if page.has_link?('Asymptomatic')
  end
end
