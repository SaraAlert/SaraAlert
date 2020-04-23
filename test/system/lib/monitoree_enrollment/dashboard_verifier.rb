# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'info_page_verifier'
require_relative '../system_test_utils'

class MonitoreeEnrollmentDashboardVerifier < ApplicationSystemTestCase
  @@monitoree_enrollment_info_page_verifier = MonitoreeEnrollmentInfoPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_monitoree_info_on_dashboard(monitoree, is_epi=false, go_back=true)
    displayed_name = search_for_monitoree(monitoree, is_epi)
    click_on displayed_name
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(monitoree, is_epi)
    @@system_test_utils.return_to_dashboard('exposure', is_epi) if go_back
  end

  def verify_group_member_on_dashboard(existing_monitoree, new_monitoree, is_epi=false)
    displayed_name = search_for_monitoree(new_monitoree, is_epi)
    click_on displayed_name
    @@monitoree_enrollment_info_page_verifier.verify_group_member_info(existing_monitoree, new_monitoree, is_epi)
    click_on 'Click here to view that monitoree'
    @@monitoree_enrollment_info_page_verifier.verify_monitoree_info(existing_monitoree, is_epi)
    @@system_test_utils.return_to_dashboard('exposure', is_epi)
  end

  def verify_monitoree_info_not_on_dashboard(monitoree, is_epi=false)
    displayed_name = @@system_test_utils.get_displayed_name(monitoree)
    displayed_birthday = @@system_test_utils.format_date(monitoree['identification']['date_of_birth'])
    search_and_verify_nonexistence("#{monitoree['identification']['first_name']} #{monitoree['identification']['last_name']} #{displayed_birthday}", is_epi)
  end

  def search_for_monitoree(monitoree, is_epi)
    displayed_name = @@system_test_utils.get_displayed_name(monitoree)
    displayed_birthday = @@system_test_utils.format_date(monitoree['identification']['date_of_birth'])
    search_and_verify_existence(monitoree['identification']['first_name'], displayed_name, displayed_birthday, is_epi)
    search_and_verify_existence(monitoree['identification']['last_name'], displayed_name, displayed_birthday, is_epi)
    displayed_name
  end

  def search_and_verify_existence(query, displayed_name, displayed_birthday, is_epi)
    click_on 'Asymptomatic' if is_epi
    fill_in 'Search:', with: query
    assert page.has_content?(displayed_name), @@system_test_utils.get_err_msg('Dashboard', 'name', displayed_name)
    assert page.has_content?(displayed_birthday), @@system_test_utils.get_err_msg('Dashboard', 'birthday', displayed_birthday)
  end

  def search_and_verify_nonexistence(query, is_epi)
    click_on 'Asymptomatic' if is_epi
    fill_in 'Search:', with: query
    assert page.has_content?('No matching records found'), @@system_test_utils.get_err_msg('Dashboard', 'monitoree', 'non-existent')
  end

  def verify_enrollment_analytics(jurisdiction_id)
    system_stats = find('h5', text: 'System Statistics').first(:xpath, '..').all(:css, 'h1.display-1')
    your_stats = find('h5', text: 'Your Statistics').first(:xpath, '..').all(:css, 'h1.display-1')
    stats = {
      system_total_subjects: system_stats[0].text.to_i,
      system_new_subjects: system_stats[1].text.to_i,
      system_total_reports: system_stats[2].text.to_i,
      system_new_reports: system_stats[3].text.to_i,
      your_total_subjects: your_stats[0].text.to_i,
      your_new_subjects: your_stats[1].text.to_i,
      your_total_reports: your_stats[2].text.to_i,
      your_new_reports: your_stats[3].text.to_i
    }
    validate_enrollment_stats(stats)
  end
  
  def validate_enrollment_stats(stats)
    assert_operator stats.fetch(:system_total_subjects), :>=, stats.fetch(:your_total_subjects)
    assert_operator stats.fetch(:system_new_subjects), :>=, stats.fetch(:your_new_subjects)
    assert_operator stats.fetch(:system_total_reports), :>=, stats.fetch(:your_total_reports)
    assert_operator stats.fetch(:system_new_reports), :>=, stats.fetch(:your_new_reports)
    assert_operator stats.fetch(:system_total_subjects), :>=, stats.fetch(:system_new_subjects)
    assert_operator stats.fetch(:system_total_reports), :>=, stats.fetch(:system_new_reports)
    assert_operator stats.fetch(:your_total_subjects), :>=, stats.fetch(:your_new_subjects)
    assert_operator stats.fetch(:your_total_reports), :>=, stats.fetch(:your_new_reports)
  end
end
