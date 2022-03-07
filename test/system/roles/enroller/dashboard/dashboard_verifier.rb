# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../patient_page/patient_page_verifier'
require_relative '../../../lib/system_test_utils'

class EnrollerDashboardVerifier < ApplicationSystemTestCase
  @@enroller_patient_page_verifier = EnrollerPatientPageVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_enrolled_monitorees(user_label, jurisdiction, is_epi: false)
    creator_id = User.where(email: "#{user_label}@example.com").first
    find_by_id('all_tab').click if is_epi

    Patient.where(creator_id: creator_id).each do |patient|
      # view patient without any filters
      fill_in 'Search', with: patient.last_name.to_s
      verify_patient_info_in_enroller_table(patient, is_epi)

      Jurisdiction.find(jurisdiction.subtree_ids).each do |jur|
        fill_in 'jurisdiction_path', with: jur[:path]
        verify_patient_info_in_enroller_table(patient, is_epi) if patient.jurisdiction[:path].include?(jur[:name])

        find_by_id('exactJurisdiction').click
        sleep(1.5) # wait for data to load
        page.all('tbody tr').each do |row|
          assigned_jurisdiction_cell = row.all('td')[is_epi ? 2 : 1]
          assert_equal(jur[:name], assigned_jurisdiction_cell.text) unless assigned_jurisdiction_cell.nil?
        end
        verify_patient_info_in_enroller_table(patient, is_epi) if patient.jurisdiction[:path] == jur[:path]
        find_by_id('allJurisdictions').click
      end
      fill_in 'jurisdiction_path', with: jurisdiction[:path]

      # view patient with assigned user filter
      if patient[:assigned_user].nil?
        find_by_id('noAssignedUser').click
      else
        fill_in 'assigned_user', with: patient[:assigned_user]
      end
      verify_patient_info_in_enroller_table(patient, is_epi)
      find_by_id('allAssignedUsers').click
    end
  end

  def verify_monitoree_info_on_dashboard(monitoree, is_epi: false, go_back: true)
    displayed_name = search_for_monitoree(monitoree, is_epi)
    click_on displayed_name
    @@enroller_patient_page_verifier.verify_monitoree_info(monitoree, is_epi: is_epi)
    @@system_test_utils.return_to_dashboard('exposure', is_epi: is_epi) if go_back
  end

  def verify_group_member_on_dashboard(existing_monitoree, new_monitoree, is_epi: false)
    displayed_name = search_for_monitoree(new_monitoree, is_epi)
    click_on displayed_name
    @@enroller_patient_page_verifier.verify_group_member_info(existing_monitoree, new_monitoree, is_epi: is_epi)
    find('#dependent-hoh-link').click
    @@enroller_patient_page_verifier.verify_monitoree_info(existing_monitoree, is_epi: is_epi)
    @@system_test_utils.return_to_dashboard('exposure', is_epi: is_epi)
  end

  def verify_monitoree_info_not_on_dashboard(monitoree, is_epi: false)
    displayed_birthday = monitoree['identification']['date_of_birth']
    search_and_verify_nonexistence("#{monitoree['identification']['first_name']} #{monitoree['identification']['last_name']} #{displayed_birthday}",
                                   is_epi)
  end

  def search_for_monitoree(monitoree, is_epi)
    displayed_name = @@system_test_utils.get_displayed_name(monitoree)
    search_and_verify_existence(monitoree['identification']['first_name'], displayed_name, monitoree['identification']['date_of_birth'],
                                is_epi)
    search_and_verify_existence(monitoree['identification']['last_name'], displayed_name, monitoree['identification']['date_of_birth'],
                                is_epi)
    displayed_name
  end

  def search_and_verify_existence(query, displayed_name, displayed_birthday, is_epi)
    click_on 'Asymptomatic' if is_epi
    fill_in is_epi ? 'search' : 'Search', with: query
    assert page.has_content?(displayed_name), @@system_test_utils.get_err_msg('Dashboard', 'name', displayed_name)
    assert page.has_content?(displayed_birthday), @@system_test_utils.get_err_msg('Dashboard', 'birthday', displayed_birthday)
  end

  def search_and_verify_nonexistence(query, is_epi)
    click_on 'Asymptomatic' if is_epi
    fill_in is_epi ? 'search' : 'Search', with: query
    assert page.has_content?('No data available in table.'), @@system_test_utils.get_err_msg('Dashboard', 'monitoree', 'non-existent')
  end

  def verify_patient_info_in_enroller_table(patient, is_epi)
    verify_patient_field_in_enroller_table('first name', patient.first_name)
    verify_patient_field_in_enroller_table('last name', patient.last_name)
    verify_patient_field_in_enroller_table('assigned jurisdiction', patient.jurisdiction[:name])
    verify_patient_field_in_enroller_table('assigned user', patient.assigned_user)
    verify_patient_field_in_enroller_table('state/local id', patient.user_defined_id_statelocal)
    verify_patient_field_in_enroller_table('sex', patient.sex) unless is_epi
    verify_patient_field_in_enroller_table('date of birth', patient.date_of_birth.strftime('%m/%d/%Y'))
    verify_patient_field_in_enroller_table('enrollment date', patient.created_at.to_date.strftime('%m/%d/%Y')) unless is_epi
  end

  def verify_patient_field_in_enroller_table(field, value)
    assert page.find('tbody').has_content?(value), @@system_test_utils.get_err_msg('Patient info', field, value) unless value.nil?
  end

  def verify_enrollment_analytics
    system_stats = find('h4', text: 'System Statistics').first(:xpath, '..').all(:css, 'h3.display-3')
    your_stats = find('h4', text: 'Your Statistics').first(:xpath, '..').all(:css, 'h3.display-3')
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
