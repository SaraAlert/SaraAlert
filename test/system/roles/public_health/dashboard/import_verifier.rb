# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../../../lib/system_test_utils'

class PublicHealthMonitoringImportVerifier < ApplicationSystemTestCase
  include ImportExport
  @@system_test_utils = SystemTestUtils.new(nil)

  TELEPHONE_FIELDS = %i[primary_telephone secondary_telephone].freeze
  BOOL_FIELDS = %i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander interpretation_required
                   contact_of_known_case travel_to_affected_country_or_area was_in_health_care_facility_with_known_cases laboratory_personnel
                   healthcare_personnel crew_on_passenger_or_cargo_flight member_of_a_common_exposure_cohort].freeze
  STATE_FIELDS = %i[address_state foreign_monitored_address_state additional_planned_travel_destination_state].freeze
  MONITORED_ADDRESS_FIELDS = %i[monitored_address_line_1 monitored_address_city monitored_address_state monitored_address_line_2 monitored_address_zip].freeze
  # TODO: when workflow specific case status validation re-enabled: take out 'case_status'
  ISOLATION_FIELDS = %i[symptom_onset extended_isolation case_status].freeze
  ENUM_FIELDS = %i[ethnicity preferred_contact_method primary_telephone_type secondary_telephone_type preferred_contact_time additional_planned_travel_type
                   exposure_risk_assessment monitoring_plan case_status].freeze
  RISK_FACTOR_FIELDS = %i[contact_of_known_case was_in_health_care_facility_with_known_cases].freeze
  # TODO: when workflow specific case status validation re-enabled: uncomment
  # WORKFLOW_SPECIFIC_FIELDS = %i[case_status].freeze
  NON_IMPORTED_PATIENT_FIELDS = %i[full_status lab_1_type lab_1_specimen_collection lab_1_report lab_1_result lab_2_type lab_2_specimen_collection lab_2_report
                                   lab_2_result].freeze

  def verify_epi_x_field_validation(jurisdiction_id, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      row.each_with_index do |value, index|
        verify_validation(jurisdiction_id, workflow, EPI_X_FIELDS[index], RISK_FACTOR_FIELDS.include?(EPI_X_FIELDS[index]) ? !value.blank? : value)
      end
    end
  end

  def verify_sara_alert_format_field_validation(jurisdiction_id, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      row.each_with_index do |value, index|
        verify_validation(jurisdiction_id, workflow, SARA_ALERT_FORMAT_FIELDS[index], value)
      end
    end
  end

  def verify_epi_x_import_page(jurisdiction_id, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    find('.modal-body').all('div.card-body').each_with_index do |card, index|
      row = sheet.row(index + 2)
      verify_existence(card, 'State/Local ID', row[0], index)
      verify_existence(card, 'CDC ID', row[4], index)
      verify_existence(card, 'First Name', row[11], index)
      verify_existence(card, 'Last Name', row[10], index)
      verify_existence(card, 'DOB', row[12], index)
      verify_existence(card, 'Language', row[7], index)
      verify_existence(card, 'Flight or Vessel Number', row[1], index)
      verify_existence(card, 'Home Address Line 1', row[16], index)
      verify_existence(card, 'Home Town/City', row[17], index)
      verify_existence(card, 'Home State', normalize_state_field(row[18]), index)
      verify_existence(card, 'Home Zip', row[19], index)
      verify_existence(card, 'Monitored Address Line 1', row[20], index)
      verify_existence(card, 'Monitored Town/City', row[21], index)
      verify_existence(card, 'Monitored State', normalize_state_field(row[22]), index)
      verify_existence(card, 'Monitored Zip', row[23], index)
      verify_existence(card, 'Phone Number 1', row[28] ? Phonelib.parse(row[28], 'US').full_e164 : nil, index)
      verify_existence(card, 'Phone Number 2', row[29] ? Phonelib.parse(row[29], 'US').full_e164 : nil, index)
      verify_existence(card, 'Email', row[30], index)
      verify_existence(card, 'Exposure Location', row[35], index)
      verify_existence(card, 'Date of Departure', row[36], index)
      verify_existence(card, 'Close Contact w/ Known Case', !row[41].blank?.to_s, index)
      verify_existence(card, 'Was in HC Fac. w/ Known Cases', !row[42].blank?.to_s, index)
      if Jurisdiction.find(jurisdiction_id).all_patients_excluding_purged.where(first_name: row[11], last_name: row[10]).length > 1
        assert card.has_content?("Warning: This #{workflow == :exposure ? 'monitoree' : 'case'} already appears to exist in the system!")
      end
    end
  end

  def verify_sara_alert_format_import_page(jurisdiction_id, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    find('.modal-body').all('div.card-body').each_with_index do |card, index|
      row = sheet.row(index + 2)
      verify_existence(card, 'State/Local ID', row[15], index)
      verify_existence(card, 'CDC ID', row[16], index)
      verify_existence(card, 'First Name', row[0], index)
      verify_existence(card, 'Last Name', row[2], index)
      verify_existence(card, 'DOB', row[3], index)
      verify_existence(card, 'Language', row[11], index)
      verify_existence(card, 'Flight or Vessel Number', row[53], index)
      verify_existence(card, 'Home Address Line 1', row[18], index)
      verify_existence(card, 'Home Town/City', row[19], index)
      verify_existence(card, 'Home State', normalize_state_field(row[20]), index)
      verify_existence(card, 'Home Zip', row[22], index)
      verify_existence(card, 'Monitored Address Line 1', row[31], index)
      verify_existence(card, 'Monitored Town/City', row[32], index)
      verify_existence(card, 'Monitored State', normalize_state_field(row[33]), index)
      verify_existence(card, 'Monitored Zip', row[35], index)
      verify_existence(card, 'Phone Number 1', row[28] ? Phonelib.parse(row[44], 'US').full_e164 : nil, index)
      verify_existence(card, 'Phone Number 2', row[29] ? Phonelib.parse(row[46], 'US').full_e164 : nil, index)
      verify_existence(card, 'Email', row[49], index)
      verify_existence(card, 'Exposure Location', row[67], index)
      verify_existence(card, 'Date of Departure', row[51], index)
      verify_existence(card, 'Close Contact w/ Known Case', row[69] ? row[69].to_s.downcase : nil, index)
      verify_existence(card, 'Was in HC Fac. w/ Known Cases', row[72] ? row[72].to_s.downcase : nil, index)
      if Jurisdiction.find(jurisdiction_id).all_patients_excluding_purged.where(first_name: row[0], middle_name: row[1], last_name: row[2]).length > 1
        assert card.has_content?("Warning: This #{workflow == :exposure ? 'monitoree' : 'case'} already appears to exist in the system!")
      end
      assert card.has_content?("This #{workflow == :exposure ? 'monitoree' : 'case'} will be imported into '#{row[95]}'") if row[95]
      assert card.has_content?("This #{workflow == :exposure ? 'monitoree' : 'case'} will be assigned to user '#{row[96]}'") if row[96]
    end
  end

  def verify_epi_x_import_data(jurisdiction_id, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xlsx(file_name).sheet(0)
    sleep(2) # wait for db write
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      patients = Jurisdiction.find(jurisdiction_id).all_patients_excluding_purged.where(first_name: row[11], last_name: row[10], date_of_birth: row[12])
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{row[11]} #{row[10]} in row #{row_num}")
      else
        assert_not_nil(patient, "Patient not found in db: #{row[11]} #{row[10]} in row #{row_num}")
        EPI_X_FIELDS.each_with_index do |field, index|
          if TELEPHONE_FIELDS.include?(field)
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :sex && !row[index].blank?
            assert_equal(SEX_ABBREVIATIONS[row[index].to_sym], patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :address_state || (field == :monitored_address_state && !row[index].nil?)
            assert_equal(normalize_state_field(row[index].to_s), patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :monitored_address_state && row[index].nil? # copy over monitored address state if state is nil
            assert_equal(normalize_state_field(row[index - 4].to_s), patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif MONITORED_ADDRESS_FIELDS.include?(field) && row[index].nil? # copy over address fields if address is nil
            assert_equal(row[index - 4].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :potential_exposure_location # copy over potential exposure country to location
            assert_equal(row[index + 1].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif RISK_FACTOR_FIELDS.include?(field)
            assert_equal(!row[index].blank?, patient[field], "#{field} mismatch in row #{row_num}")
          elsif !field.nil?
            assert_equal(row[index].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          end
        end
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_num}")
      end
    end
  end

  def verify_sara_alert_format_import_data(jurisdiction_id, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xlsx(file_name).sheet(0)
    sleep(2) # wait for db write
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      user_jurisdiction = Jurisdiction.find(jurisdiction_id)
      patients = user_jurisdiction.all_patients_excluding_purged.where(first_name: row[0], middle_name: row[1], last_name: row[2], date_of_birth: row[3])
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{row[0]} #{row[1]} #{row[2]} in row #{row_num}")
      else
        assert_not_nil(patient, "Patient not found in db: #{row[0]} #{row[1]} #{row[2]} in row #{row_num}")
        SARA_ALERT_FORMAT_FIELDS.each_with_index do |field, index|
          if TELEPHONE_FIELDS.include?(field)
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif BOOL_FIELDS.include?(field)
            assert_equal(normalize_bool_field(row[index]).to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif STATE_FIELDS.include?(field) || (field == :monitored_address_state && !row[index].nil?)
            assert_equal(normalize_state_field(row[index].to_s).to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :monitored_address_state && row[index].nil? # copy over monitored address state if state is nil
            assert_equal(normalize_state_field(row[index - 13].to_s), patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif MONITORED_ADDRESS_FIELDS.include?(field) & row[index].nil? # copy over address fields if address is nil
            assert_equal(row[index - 13].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :symptom_onset # isolation workflow specific field
            assert_equal(workflow == :isolation ? row[index].to_s : '', patient[field].to_s, "#{field} mismatch in row #{row_num}")
          # TODO: when workflow specific case status validation re-enabled: remove the next 3 lines
          elsif field == :case_status # isolation workflow specific enum field
            normalized_cell_value = NORMALIZED_ENUMS[field][normalize_enum_field_value(row[index])].to_s
            assert_equal(workflow == :isolation ? normalized_cell_value : '', patient[field].to_s, "#{field} mismatch in row #{row_num}")
          # TODO: when workflow specific case status validation re-enabled: uncomment
          # elsif field == :case_status
          #   normalized_cell_value = if workflow == :isolation
          #                             NORMALIZED_ISOLATION_ENUMS[field][normalize_enum_field_value(row[index])].to_s
          #                           else
          #                             NORMALIZED_EXPOSURE_ENUMS[field][normalize_enum_field_value(row[index])].to_s
          #                           end
          #   assert_equal(normalized_cell_value, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif field == :jurisdiction_path
            assert_equal(row[index] ? row[index].to_s : user_jurisdiction[:path].to_s, patient.jurisdiction[:path].to_s, "#{field} mismatch in row #{row_num}")
          elsif ENUM_FIELDS.include?(field)
            assert_equal(NORMALIZED_ENUMS[field][normalize_enum_field_value(row[index])].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif !NON_IMPORTED_PATIENT_FIELDS.include?(field)
            assert_equal(row[index].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          end
        end
        verify_laboratory(patient, row[87..90])
        verify_laboratory(patient, row[91..94])
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_num}")
      end
    end
  end

  def verify_validation(jurisdiction_id, workflow, field, value)
    return if workflow != :isolation && ISOLATION_FIELDS.include?(field)

    if VALIDATION[field]
      # TODO: Un-comment when required fields are to be checked upon import
      # if VALIDATION[field][:checks].include?(:required) && (!value || value.blank?)
      #   assert page.has_content?("Required field '#{VALIDATION[field][:label]}' is missing"), "Error message for #{field}"
      # end
      if value && !value.blank? && VALIDATION[field][:checks].include?(:enum) && !NORMALIZED_ENUMS[field].keys.include?(normalize_enum_field_value(value))
        assert page.has_content?("'#{value}' is not an acceptable value for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
      end
      # TODO: when workflow specific case status validation re-enabled: uncomment
      # if value && !value.blank? && WORKFLOW_SPECIFIC_FIELDS.include?(field)
      #   if workflow == :exposure && !NORMALIZED_EXPOSURE_ENUMS[field].keys.include?(normalize_enum_field_value(value))
      #     assert page.has_content?('for monitorees imported into the Exposure workflow'), "Error message for #{field} incorrect"
      #   elsif workflow == :isolation && !NORMALIZED_ISOLATION_ENUMS[field].keys.include?(normalize_enum_field_value(value))
      #     assert page.has_content?('for cases imported into the Isolation workflow'), "Error message for #{field} incorrect"
      #   end
      # end
      if value && !value.blank? && VALIDATION[field][:checks].include?(:bool) && !%w[true false].include?(value.to_s.downcase)
        assert page.has_content?("'#{value}' is not an acceptable value for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
      end
      if value && !value.blank? && VALIDATION[field][:checks].include?(:date) && !value.instance_of?(Date) && value.match(/\d{4}-\d{2}-\d{2}/)
        begin
          Date.parse(value)
        rescue ArgumentError
          assert page.has_content?("'#{value}' is not a valid date for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
        end
      end
      if value && !value.blank? && VALIDATION[field][:checks].include?(:date) && !value.instance_of?(Date) && !value.match(/\d{4}-\d{2}-\d{2}/)
        generic_msg = "'#{value}' is not a valid date for '#{VALIDATION[field][:label]}'"
        if value.match(%r{\d{2}/\d{2}/\d{4}})
          specific_msg = "#{generic_msg} due to ambiguity between 'MM/DD/YYYY' and 'DD/MM/YYYY', please use the 'YYYY-MM-DD' format instead"
          assert page.has_content?(specific_msg), "Error message for #{field} missing"
        else
          assert page.has_content?("#{generic_msg}, please use the 'YYYY-MM-DD' format"), "Error message for #{field} missing"
        end
      end
      if value && !value.blank? && VALIDATION[field][:checks].include?(:phone) && Phonelib.parse(value, 'US').full_e164.nil?
        assert page.has_content?("'#{value}' is not a valid phone number for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
      end
      if value && !value.blank? && VALIDATION[field][:checks].include?(:state) && !VALID_STATES.include?(value) && STATE_ABBREVIATIONS[value.upcase.to_sym].nil?
        assert page.has_content?("'#{value}' is not a valid state for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
      end
      if value && !value.blank? && VALIDATION[field][:checks].include?(:sex) && !%(Male Female Unknown M F).include?(value.capitalize)
        assert page.has_content?("'#{value}' is not a valid sex for '#{VALIDATION[field][:label]}', acceptable values are Male, Female, and Unknown"),
               "Error message for #{field} missing"
      end
      if value && !value.blank? && VALIDATION[field][:checks].include?(:email) && !ValidEmail2::Address.new(value).valid?
        assert page.has_content?("'#{value}' is not a valid Email Address for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
      end
    elsif field == :jurisdiction_path
      return unless value && !value.blank?

      jurisdiction = Jurisdiction.where(path: value).first
      if jurisdiction.nil?
        if Jurisdiction.where(name: value).empty?
          assert page.has_content?("'#{value}' is not valid for 'Full Assigned Jurisdiction Path'"), "Error message for #{field} missing"
        else
          msg = "'#{value}' is not valid for 'Full Assigned Jurisdiction Path', please provide the full path instead of just the name"
          assert page.has_content?(msg), "Error message for #{field} missing"
        end
      else
        unless Jurisdiction.find(jurisdiction_id).subtree_ids.include?(jurisdiction[:id])
          msg = "'#{value}' is not valid for 'Full Assigned Jurisdiction Path' because you do not have permission to import into it"
          assert page.has_content?(msg), "Error message for #{field} missing"
        end
      end
    elsif field == :assigned_user
      return unless value && !value.blank? && !value.to_i.between?(1, 999_999)

      msg = "'#{value}' is not valid for 'Assigned User', acceptable values are numbers between 1-999999"
      assert page.has_content?(msg), "Error message for #{field} missing"
    end
  end

  def verify_laboratory(patient, data)
    return unless !data[0].blank? || !data[1].blank? || !data[2].blank? || !data[3].blank?

    count = Laboratory.where(
      patient_id: patient.id,
      lab_type: data[0].to_s,
      specimen_collection: data[1],
      report: data[2],
      result: data[3].to_s
    ).count
    assert_equal(1, count, "Lab result for patient: #{patient.first_name} #{patient.last_name} not found")
  end

  def verify_existence(element, label, value, index)
    assert element.has_content?("#{label}:#{value && value != '' ? ' ' + value.to_s : ''}"), "#{label} should be #{value} in row #{index + 2}"
  end

  def normalize_state_field(value)
    value ? VALID_STATES.include?(value) ? value : STATE_ABBREVIATIONS[value.upcase.to_sym] : nil
  end

  def normalize_bool_field(value)
    %w[true false].include?(value.to_s.downcase) ? (value.to_s.downcase == 'true') : nil
  end

  def get_xlsx(file_name)
    Roo::Spreadsheet.open(file_fixture(file_name).to_s)
  end
end
