# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../../../lib/system_test_utils'

class PublicHealthMonitoringImportVerifier < ApplicationSystemTestCase
  include ImportExportHelper
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_epi_x_field_validation(jurisdiction_id, workflow, file_name)
    sheet = get_xslx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      row.each_with_index do |value, index|
        verify_validation(jurisdiction_id, workflow, EPI_X_FIELDS[index], [41, 42].include?(index) ? !value.blank? : value)
      end
    end
  end

  def verify_sara_alert_format_field_validation(jurisdiction_id, workflow, file_name)
    sheet = get_xslx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      row.each_with_index do |value, index|
        verify_validation(jurisdiction_id, workflow, COMPREHENSIVE_FIELDS[index], value)
      end
    end
  end

  def verify_epi_x_import_page(jurisdiction_id, file_name)
    sheet = get_xslx(file_name).sheet(0)
    page.all('div.card-body').each_with_index do |card, index|
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
      if Jurisdiction.find(jurisdiction_id).all_patients.where(first_name: row[11], last_name: row[10]).length > 1
        assert card.has_content?('Warning: This monitoree already appears to exist in the system!')
      end
    end
  end

  def verify_sara_alert_format_import_page(jurisdiction_id, file_name)
    sheet = get_xslx(file_name).sheet(0)
    page.all('div.card-body').each_with_index do |card, index|
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
      if Jurisdiction.find(jurisdiction_id).all_patients.where(first_name: row[0], middle_name: row[1], last_name: row[2]).length > 1
        assert card.has_content?('Warning: This monitoree already appears to exist in the system!')
      end
      assert card.has_content?("This monitoree will be imported into '#{row[95]}'") if row[95]
      assert card.has_content?("This monitoree will be assigned to user '#{row[96]}'") if row[96]
    end
  end

  def verify_epi_x_import_data(jurisdiction_id, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xslx(file_name).sheet(0)
    @@system_test_utils.wait_for_db_write_delay
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      patients = Jurisdiction.find(jurisdiction_id).all_patients.where(first_name: row[11], last_name: row[10], date_of_birth: row[12])
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{row[11]} #{row[10]} in row #{row_num}")
      else
        assert_not_nil(patient, "Patient not found in db: #{row[11]} #{row[10]} in row #{row_num}")
        EPI_X_FIELDS.each_with_index do |field, index|
          if [28, 29].include?(index) # phone number fields
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif index == 13 && !row[index].blank? # sex
            assert_equal(SEX_ABBREVIATIONS[row[index].to_sym], patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif index == 18 || (index == 22 && !row[22].nil?) # state fields
            assert_equal(normalize_state_field(row[index].to_s), patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif index == 22 && row[22].nil? # copy over monitored address state if state is nil
            assert_equal(normalize_state_field(row[index - 4].to_s), patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif [20, 21, 23].include?(index) && row[index].nil? # copy over address fields if address is nil
            assert_equal(row[index - 4].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif index == 34 # copy over potential exposure country to location
            assert_equal(row[35].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif [41, 42].include?(index) # contact of known case and was in healthcare facilities
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
    sheet = get_xslx(file_name).sheet(0)
    @@system_test_utils.wait_for_db_write_delay
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      user_jurisdiction = Jurisdiction.find(jurisdiction_id)
      patients = user_jurisdiction.all_patients.where(first_name: row[0], middle_name: row[1], last_name: row[2], date_of_birth: row[3])
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{row[0]} #{row[1]} #{row[2]} in row #{row_num}")
      else
        assert_not_nil(patient, "Patient not found in db: #{row[0]} #{row[1]} #{row[2]} in row #{row_num}")
        COMPREHENSIVE_FIELDS.each_with_index do |field, index|
          if [44, 46].include?(index) # phone number fields
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif [5, 6, 7, 8, 9, 13, 69, 71, 72, 74, 76, 78, 79].include?(index) # bool fields
            assert_equal(normalize_bool_field(row[index]).to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif [20, 39, 60].include?(index) || (index == 33 && !row[33].nil?) # state fields
            assert_equal(normalize_state_field(row[index].to_s).to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif index == 33 && row[33].nil? # copy over monitored address state if state is nil
            assert_equal(normalize_state_field(row[index - 13].to_s), patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif [31, 32, 33, 34, 35].include?(index) & row[index].nil? # copy over address fields if address is nil
            assert_equal(row[index - 13].to_s, patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif [85, 86].include?(index) # isolation workflow specific fields
            assert_equal(workflow == :isolation ? row[index].to_s : '', patient[field].to_s, "#{field} mismatch in row #{row_num}")
          elsif index == 95 # jurisdiction_path
            assert_equal(row[index] ? row[index].to_s : user_jurisdiction[:path].to_s, patient.jurisdiction[:path].to_s, "#{field} mismatch in row #{row_num}")
          elsif !field.nil?
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
    return if workflow != :isolation && %i[symptom_onset case_status].include?(field)

    if VALIDATION[field]
      # TODO: Un-comment when required fields are to be checked upon import
      # if VALIDATION[field][:checks].include?(:required) && (!value || value.blank?)
      #   assert page.has_content?("Required field '#{VALIDATION[field][:label]}' is missing"), "Error message for #{field}"
      # end
      if value && !value.blank? && VALIDATION[field][:checks].include?(:enum) && !VALID_ENUMS[field].include?(value)
        assert page.has_content?("'#{value}' is not an acceptable value for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
      end
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
        if value.match(%r{\d{2}\/\d{2}\/\d{4}})
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
        assert page.has_content?("'#{value}' is not a valid sex for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
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
      return unless value && !value.blank? && !value.to_i.between?(1, 9999)

      msg = "'#{value}' is not valid for 'Assigned User', acceptable values are numbers between 1-9999"
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

  def get_xslx(file_name)
    Roo::Spreadsheet.open(file_fixture(file_name).to_s)
  end
end
