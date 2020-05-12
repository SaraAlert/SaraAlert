# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../system_test_utils'

class PublicHealthMonitoringImportVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)
    
  DB_WRITE_DELAY = 0.8
  
  EPI_X_FIELDS = [:user_defined_id_statelocal, :flight_or_vessel_number, nil, nil, :user_defined_id_cdc, nil, nil, :primary_language, :date_of_arrival,
                  :port_of_entry_into_usa, :last_name, :first_name, :date_of_birth, :sex, nil, nil, :address_line_1, :address_city, :address_state,
                  :address_zip, :monitored_address_line_1, :monitored_address_city, :monitored_address_state, :monitored_address_zip, nil, nil, nil, nil,
                  :primary_telephone, :secondary_telephone, :email, nil, nil, nil, :potential_exposure_location, :potential_exposure_country,
                  :date_of_departure, nil, nil, nil, nil, :contact_of_known_case, :was_in_health_care_facility_with_known_cases].freeze

  COMPREHENSIVE_FIELDS = [:first_name, :middle_name, :last_name, :date_of_birth, :sex, :white, :black_or_african_american, :american_indian_or_alaska_native,
                          :asian, :native_hawaiian_or_other_pacific_islander, :ethnicity, :primary_language, :secondary_language, :interpretation_required,
                          :nationality, :user_defined_id_statelocal, :user_defined_id_cdc, :user_defined_id_nndss, :address_line_1, :address_city,
                          :address_state, :address_line_2, :address_zip, :address_county, :foreign_address_line_1, :foreign_address_city,
                          :foreign_address_country, :foreign_address_line_2, :foreign_address_zip, :foreign_address_line_3, :foreign_address_state,
                          :monitored_address_line_1, :monitored_address_city, :monitored_address_state, :monitored_address_line_2, :monitored_address_zip,
                          :monitored_address_county, :foreign_monitored_address_line_1, :foreign_monitored_address_city, :foreign_monitored_address_state,
                          :foreign_monitored_address_line_2, :foreign_monitored_address_zip, :foreign_monitored_address_county, :preferred_contact_method,
                          :primary_telephone, :primary_telephone_type, :secondary_telephone, :secondary_telephone_type, :preferred_contact_time, :email,
                          :port_of_origin, :date_of_departure, :source_of_report, :flight_or_vessel_number, :flight_or_vessel_carrier, :port_of_entry_into_usa,
                          :date_of_arrival, :travel_related_notes, :additional_planned_travel_type, :additional_planned_travel_destination,
                          :additional_planned_travel_destination_state, :additional_planned_travel_destination_country,
                          :additional_planned_travel_port_of_departure, :additional_planned_travel_start_date, :additional_planned_travel_end_date,
                          :additional_planned_travel_related_notes, :last_date_of_exposure, :potential_exposure_location, :potential_exposure_country,
                          :contact_of_known_case, :contact_of_known_case_id, :travel_to_affected_country_or_area, :was_in_health_care_facility_with_known_cases,
                          :was_in_health_care_facility_with_known_cases_facility_name, :laboratory_personnel, :laboratory_personnel_facility_name,
                          :healthcare_personnel, :healthcare_personnel_facility_name, :crew_on_passenger_or_cargo_flight, :member_of_a_common_exposure_cohort,
                          :member_of_a_common_exposure_cohort_type, :exposure_risk_assessment, :monitoring_plan, :exposure_notes].freeze
  
  def verify_epi_x_selection(jurisdiction_id, workflow, file_name, rejects)
    sheet = get_xslx(file_name).sheet(0)
  end

  def verify_sara_alert_format_selection(jurisdiction_id, workflow, file_name, rejects)
    sheet = get_xslx(file_name).sheet(0)
  end

  def verify_epi_x_import(jurisdiction_id, workflow, file_name, rejects)
    sheet = get_xslx(file_name).sheet(0)
    sleep(DB_WRITE_DELAY)
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_index|
      row = sheet.row(row_index)
      patient = Patient.where(first_name: row[11], last_name: row[10])[0]
      if rejects.include?(row_index - 2)
        assert_nil(patient, "Patient should not be found in db: #{row[11]} #{row[10]}")
      else
        assert_not_nil(patient, "Patient not found in db: #{row[11]} #{row[10]}")
        EPI_X_FIELDS.each_with_index do |field, index|
          if index == 28 || index == 29
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch")
          elsif index == 13
            assert_equal(row[index] == 'M' ? 'Male' : 'Female', patient[field].to_s, "#{field} mismatch")
          elsif [20, 21, 22, 23].include?(index) && row[index].nil?
            assert_equal(row[index - 4].to_s, patient[field].to_s, "#{field} mismatch")
          elsif index == 34
            assert_equal(row[35].to_s, patient[field].to_s, "#{field} mismatch")
          elsif index == 41 || index == 42
            assert_equal(!row[index].blank?, patient[field], "#{field} mismatch")
          elsif !field.nil?
            assert_equal(row[index].to_s, patient[field].to_s, "#{field} mismatch")
          end
        end
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow")
      end
    end
  end

  def verify_sara_alert_format_import(jurisdiction_id, workflow, file_name, rejects)
    sheet = get_xslx(file_name).sheet(0)
    sleep(DB_WRITE_DELAY)
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_index|
      row = sheet.row(row_index)
      patient = Patient.where(first_name: row[0], middle_name: row[1], last_name: row[2])[0]
      if rejects.include?(row_index - 2)
        assert_nil(patient, "Patient should not be found in db: #{row[0]} #{row[1]} #{row[2]}")
      else
        assert_not_nil(patient, "Patient not found in db: #{row[0]} #{row[1]} #{row[2]}")
        COMPREHENSIVE_FIELDS.each_with_index do |field, index|
          if index == 44 || index == 46
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch")
          else
            assert_equal(row[index], patient[field].to_s, "#{field} mismatch")
          end
        end
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow")
      end
    end
  end

  def get_xslx(file_name)
    Roo::Spreadsheet.open(file_fixture(file_name).to_s)
  end
end
