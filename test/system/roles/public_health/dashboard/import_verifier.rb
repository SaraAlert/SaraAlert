# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../../../lib/system_test_utils'

class PublicHealthMonitoringImportVerifier < ApplicationSystemTestCase
  include ExportHelper
  include PatientHelper
  @@system_test_utils = SystemTestUtils.new(nil)

  TELEPHONE_FIELDS = %i[primary_telephone secondary_telephone].freeze
  BOOL_FIELDS = %i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander race_other race_unknown
                   race_refused_to_answer interpretation_required contact_of_known_case travel_to_affected_country_or_area
                   was_in_health_care_facility_with_known_cases laboratory_personnel healthcare_personnel crew_on_passenger_or_cargo_flight
                   member_of_a_common_exposure_cohort].freeze
  STATE_FIELDS = %i[address_state foreign_monitored_address_state additional_planned_travel_destination_state].freeze
  MONITORED_ADDRESS_FIELDS = %i[monitored_address_line_1 monitored_address_city monitored_address_state monitored_address_line_2 monitored_address_zip].freeze
  # TODO: when workflow specific case status validation re-enabled: take out 'case_status'
  ISOLATION_FIELDS = %i[symptom_onset extended_isolation case_status].freeze
  ENUM_FIELDS = %i[ethnicity preferred_contact_method primary_telephone_type secondary_telephone_type additional_planned_travel_type exposure_risk_assessment
                   monitoring_plan case_status].freeze
  TIME_FIELDS = %i[preferred_contact_time].freeze
  RISK_FACTOR_FIELDS = %i[contact_of_known_case was_in_health_care_facility_with_known_cases].freeze
  # TODO: when workflow specific case status validation re-enabled: uncomment
  # WORKFLOW_SPECIFIC_FIELDS = %i[case_status].freeze
  NON_IMPORTED_PATIENT_FIELDS = %i[full_status lab_1_type lab_1_specimen_collection lab_1_report lab_1_result lab_2_type lab_2_specimen_collection lab_2_report
                                   lab_2_result vaccine_1_group_name vaccine_1_product_name vaccine_1_administration_date vaccine_1_dose_number vaccine_1_notes
                                   vaccine_2_group_name vaccine_2_product_name vaccine_2_administration_date vaccine_2_dose_number vaccine_2_notes].freeze
  EPI_X_MONITORED_ADDRESS_FIELDS = {
    monitored_address_line_1: :address_line_1,
    monitored_address_city: :address_city,
    monitored_address_state: :address_state
  }.freeze

  def verify_epi_x_field_validation(jurisdiction, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      row.each_with_index do |value, index|
        verify_validation(:epix, jurisdiction, workflow, EPI_X_FIELDS[index], RISK_FACTOR_FIELDS.include?(EPI_X_FIELDS[index]) ? value.present? : value)
      end
    end
  end

  def verify_sara_alert_format_field_validation(jurisdiction, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      row.each_with_index do |value, index|
        verify_validation(:saf, jurisdiction, workflow, SARA_ALERT_FORMAT_FIELDS[index], value)
      end
    end
  end

  def verify_epi_x_import_page(jurisdiction, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    find('.modal-body').all('div.card-body').each_with_index do |card, index|
      row = sheet.row(index + 2)
      verify_existence(card, 'CDC ID', displayed_epi_x_val(row, :user_defined_id_cdc), index)
      verify_existence(card, 'First Name', displayed_epi_x_val(row, :first_name), index)
      verify_existence(card, 'Last Name', displayed_epi_x_val(row, :last_name), index)
      verify_existence(card, 'DOB', displayed_epi_x_val(row, :date_of_birth), index)
      verify_existence(card, 'Flight or Vessel Number', displayed_epi_x_val(row, :flight_or_vessel_number), index)
      country = displayed_epi_x_val(row, :foreign_address_country)
      if country.blank? || country.downcase.strip == 'united states'
        verify_existence(card, 'Home Address Line 1', displayed_epi_x_val(row, :address_line_1), index)
        verify_existence(card, 'Home Town/City', displayed_epi_x_val(row, :address_city), index)
        verify_existence(card, 'Home State', normalize_state_field(displayed_epi_x_val(row, :address_state)), index)
        verify_existence(card, 'Home Zip', displayed_epi_x_val(row, :address_zip), index)
      end
      verify_existence(card, 'Monitored Address Line 1', displayed_epi_x_val(row, :monitored_address_line_1), index)
      verify_existence(card, 'Monitored Town/City', displayed_epi_x_val(row, :monitored_address_city), index)
      verify_existence(card, 'Monitored State', normalize_state_field(displayed_epi_x_val(row, :monitored_address_state)), index)
      verify_existence(card, 'Phone Number 1', displayed_epi_x_val(row, :primary_telephone), index)
      verify_existence(card, 'Phone Number 2', displayed_epi_x_val(row, :secondary_telephone), index)
      verify_existence(card, 'Email', displayed_epi_x_val(row, :email), index)
      verify_existence(card, 'Date of Departure', displayed_epi_x_val(row, :date_of_departure), index)
      if jurisdiction.all_patients_excluding_purged.where(first_name: epi_x_val(row, :first_name), last_name: epi_x_val(row, :last_name)).length > 1
        assert card.has_content?("Warning: This #{workflow == :exposure ? 'monitoree' : 'case'} already appears to exist in the system!")
      end
    end
  end

  def verify_sara_alert_format_import_page(jurisdiction, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    find('.modal-body').all('div.card-body').each_with_index do |card, index|
      row = sheet.row(index + 2)
      verify_existence(card, 'State/Local ID', displayed_saf_val(row, :user_defined_id_statelocal), index)
      verify_existence(card, 'CDC ID', displayed_saf_val(row, :user_defined_id_cdc), index)
      verify_existence(card, 'First Name', displayed_saf_val(row, :first_name), index)
      verify_existence(card, 'Last Name', displayed_saf_val(row, :last_name), index)
      verify_existence(card, 'DOB', displayed_saf_val(row, :date_of_birth), index)
      verify_existence(card, 'Language', displayed_saf_val(row, :primary_language), index)
      verify_existence(card, 'Flight or Vessel Number', displayed_saf_val(row, :flight_or_vessel_number), index)
      verify_existence(card, 'Home Address Line 1', displayed_saf_val(row, :address_line_1), index)
      verify_existence(card, 'Home Town/City', displayed_saf_val(row, :address_city), index)
      verify_existence(card, 'Home State', normalize_state_field(displayed_saf_val(row, :address_state)), index)
      verify_existence(card, 'Home Zip', displayed_saf_val(row, :address_zip), index)
      verify_existence(card, 'Monitored Address Line 1', displayed_saf_val(row, :monitored_address_line_1), index)
      verify_existence(card, 'Monitored Town/City', displayed_saf_val(row, :monitored_address_city), index)
      verify_existence(card, 'Monitored State', normalize_state_field(displayed_saf_val(row, :monitored_address_state)), index)
      verify_existence(card, 'Monitored Zip', displayed_saf_val(row, :monitored_address_zip), index)
      verify_existence(card, 'Phone Number 1', displayed_saf_val(row, :primary_telephone), index)
      verify_existence(card, 'Phone Number 2', displayed_saf_val(row, :secondary_telephone), index)
      verify_existence(card, 'Email', displayed_saf_val(row, :email), index)
      verify_existence(card, 'Exposure Location', displayed_saf_val(row, :potential_exposure_location), index)
      verify_existence(card, 'Date of Departure', displayed_saf_val(row, :date_of_departure), index)
      verify_existence(card, 'Close Contact w/ Known Case', displayed_saf_val(row, :contact_of_known_case)&.to_s&.downcase, index)
      verify_existence(card, 'Was in HC Fac. w/ Known Cases', displayed_saf_val(row, :was_in_health_care_facility_with_known_cases)&.to_s&.downcase, index)
      if jurisdiction.all_patients_excluding_purged
                     .where(first_name: saf_val(row, :first_name), middle_name: saf_val(row, :middle_name), last_name: :last_name).length > 1
        assert card.has_content?("Warning: This #{workflow == :exposure ? 'monitoree' : 'case'} already appears to exist in the system!")
      end
      if saf_val(row, :jurisdiction_path)
        assert card.has_content?("This #{workflow == :exposure ? 'monitoree' : 'case'} will be imported into '#{saf_val(row, :jurisdiction_path)}'"),
               "Jurisdiction path for row #{index + 1} should be #{saf_val(row, :assigned_user)}"
      end
      if saf_val(row, :assigned_user)
        assert card.has_content?("This #{workflow == :exposure ? 'monitoree' : 'case'} will be assigned to user '#{saf_val(row, :assigned_user)}'"),
               "Assigned user for row #{index + 1} should be #{saf_val(row, :assigned_user)}"
      end
    end
  end

  def verify_epi_x_import_data(jurisdiction, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xlsx(file_name).sheet(0)
    sleep(2) # wait for db write
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      patients = jurisdiction.all_patients_excluding_purged.where(first_name: epi_x_val(row, :first_name))
                             .where(last_name: epi_x_val(row, :last_name)).where(date_of_birth: epi_x_val(row, :date_of_birth))
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      international_address = epi_x_val(row, :foreign_address_country).present? && epi_x_val(row, :foreign_address_country)&.strip&.downcase != 'united states'
      if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{epi_x_val(row, :first_name)} #{epi_x_val(row, :last_name)} in row #{row_num}")
      else
        assert_not_nil(patient, "Patient not found in db: #{epi_x_val(row, :first_name)} #{epi_x_val(row, :last_name)} in row #{row_num}")
        EPI_X_FIELDS.each_with_index do |field, index|
          err_msg = "#{field} mismatch in row #{row_num}"
          # import primary_telephone before secondary_telephone
          if field == :primary_telephone && row[EPI_X_FIELDS.index(:primary_telephone)].blank?
            assert_equal(Phonelib.parse(row[EPI_X_FIELDS.index(:secondary_telephone)], 'US').full_e164, patient[:primary_telephone].to_s, err_msg)
          elsif field == :secondary_telephone && row[EPI_X_FIELDS.index(:primary_telephone)].blank?
            assert_equal('', patient[:secondary_telephone].to_s, err_msg)
          elsif TELEPHONE_FIELDS.include?(field)
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, err_msg)
          elsif field == :sex && row[index].present?
            assert_equal(SEX_ABBREVIATIONS[row[index].upcase.to_sym] || row[index]&.downcase&.capitalize, patient[field].to_s, err_msg)
          elsif %i[primary_language secondary_language].include?(field) && row[index].present?
            assert_equal(Languages.normalize_and_get_language_code(row[index])&.to_s, patient[field].to_s, err_msg)
          # only import foreign address country if it's not united states
          elsif field == :foreign_address_country
            assert_equal(international_address ? row[index].to_s : '', patient[field].to_s, err_msg)
          # import address to international address if international
          elsif international_address && %i[address_line_1 address_city address_zip address_line_2].include?(field)
            assert_equal(row[index].to_s, patient[ImportController::FOREIGN_ADDRESS_MAPPINGS[field]].to_s, err_msg)
          elsif international_address && field == :address_state
            assert_equal(normalize_state_field(row[index].to_s), patient[ImportController::FOREIGN_ADDRESS_MAPPINGS[field]].to_s, err_msg)
          # normalize state fields
          elsif field == :address_state || (field == :monitored_address_state && row[index].present?)
            assert_equal(normalize_state_field(row[index].to_s).to_s, patient[field].to_s, err_msg)
          # these fields come from multiple columns
          elsif %i[travel_related_notes port_of_entry_into_usa].include?(field)
            assert patient[field].to_s.include?(row[index].to_s), err_msg
          # format dates
          elsif %i[date_of_birth date_of_departure symptom_onset].include?(field)
            assert_equal(row[index].present? ? Date.strptime(row[index], '%m/%d/%Y').to_s : '', patient[field].to_s, err_msg)
          elsif field == :date_of_arrival
            assert_equal(row[index].present? ? Date.strptime(row[index], '%b %d %Y').to_s : '', patient[field].to_s, err_msg)
          elsif !field.nil?
            assert_equal(row[index].to_s, patient[field].to_s, err_msg)
          end
        end
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_num}")
      end
    end
  end

  def verify_sara_alert_format_import_data(jurisdiction, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xlsx(file_name).sheet(0)
    sleep(2) # wait for db write
    rejects = [] if rejects.nil?
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      patients = jurisdiction.all_patients_excluding_purged.where(first_name: saf_val(row, :first_name)).where(middle_name: saf_val(row, :middle_name))
                             .where(last_name: saf_val(row, :last_name), date_of_birth: saf_val(row, :date_of_birth))
      patient = patients.where('created_at > ?', 1.minute.ago)[0]
      duplicate = patients.where('created_at < ?', 1.minute.ago).exists?
      if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)
        assert_nil(patient, "Patient should not be found in db: #{saf_val(row, :first_name)} #{saf_val(row, :middle_name)} #{saf_val(row, :last_name)}"\
                            " in row #{row_num}")
      else
        assert_not_nil(patient, "Patient not found in db: #{saf_val(row, :first_name)} #{saf_val(row, :middle_name)} #{saf_val(row, :last_name)}"\
                                " in row #{row_num}")
        SARA_ALERT_FORMAT_FIELDS.each_with_index do |field, index|
          err_msg = "#{field} mismatch in row #{row_num}"
          if TELEPHONE_FIELDS.include?(field)
            assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, err_msg)
          elsif BOOL_FIELDS.include?(field)
            assert_equal(normalize_bool_field(row[index]).to_s, patient[field].to_s, err_msg)
          elsif STATE_FIELDS.include?(field) || (field == :monitored_address_state && !row[index].nil?)
            assert_equal(normalize_state_field(row[index].to_s).to_s, patient[field].to_s, err_msg)
          elsif field == :symptom_onset # isolation workflow specific field
            assert_equal(workflow == :isolation ? row[index].to_s : '', patient[field].to_s, err_msg)
          # TODO: when workflow specific case status validation re-enabled: remove the next 3 lines
          elsif field == :case_status # isolation workflow specific enum field
            normalized_cell_value = NORMALIZED_ENUMS[field][normalize_enum_field_value(row[index])].to_s
            assert_equal(workflow == :isolation ? normalized_cell_value : '', patient[field].to_s, err_msg)
          # TODO: when workflow specific case status validation re-enabled: uncomment
          # elsif field == :case_status
          #   normalized_cell_value = if workflow == :isolation
          #                             NORMALIZED_ISOLATION_ENUMS[field][normalize_enum_field_value(row[index])].to_s
          #                           else
          #                             NORMALIZED_EXPOSURE_ENUMS[field][normalize_enum_field_value(row[index])].to_s
          #                           end
          #   assert_equal(normalized_cell_value, patient[field].to_s, err_msg)
          elsif %i[primary_language secondary_language].include?(field) && row[index].present?
            assert_equal(Languages.normalize_and_get_language_code(row[index])&.to_s, patient[field].to_s, err_msg)
          elsif field == :jurisdiction_path
            assert_equal(row[index] ? row[index].to_s : jurisdiction[:path].to_s, patient.jurisdiction[:path].to_s, err_msg)
          elsif ENUM_FIELDS.include?(field)
            assert_equal(NORMALIZED_ENUMS[field][normalize_enum_field_value(row[index])].to_s, patient[field].to_s, err_msg)
          elsif TIME_FIELDS.include?(field)
            assert_equal(NORMALIZED_INVERTED_TIME_OPTIONS[normalize_enum_field_value(row[index])].to_s, patient[field].to_s, err_msg)
          elsif NON_IMPORTED_PATIENT_FIELDS.exclude?(field)
            assert_equal(row[index].to_s, patient[field].to_s, err_msg)
          end
        end
        verify_laboratory(patient, row[87..90]) if row[87..90].filter(&:present?).any?
        verify_laboratory(patient, row[91..94]) if row[91..94].filter(&:present?).any?
        verify_vaccine(patient, row[102..106]) if row[102..106].filter(&:present?).any?
        verify_vaccine(patient, row[107..111]) if row[107..111].filter(&:present?).any?
        assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_num}")
      end
    end
  end

  def verify_validation(format, jurisdiction, workflow, field, value)
    return if workflow != :isolation && ISOLATION_FIELDS.include?(field)

    if VALIDATION[field]
      checks = VALIDATION[field][:checks]
      # TODO: Un-comment when required fields are to be checked upon import
      # if checks.include?(:required) && (!value || value.blank?)
      #   assert page.has_content?("Required field '#{VALIDATION[field][:label]}' is missing"), "Error message for #{field}"
      # end
      if value && value.present? && checks.include?(:enum) && !NORMALIZED_ENUMS[field].key?(normalize_enum_field_value(value))
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not an acceptable value"), "Error message for #{field} missing"
      end
      # TODO: when workflow specific case status validation re-enabled: uncomment
      # if value && value.present? && WORKFLOW_SPECIFIC_FIELDS.include?(field)
      #   if workflow == :exposure && !NORMALIZED_EXPOSURE_ENUMS[field].keys.include?(normalize_enum_field_value(value))
      #     assert page.has_content?('for monitorees imported into the Exposure workflow'), "Error message for #{field} incorrect"
      #   elsif workflow == :isolation && !NORMALIZED_ISOLATION_ENUMS[field].keys.include?(normalize_enum_field_value(value))
      #     assert page.has_content?('for cases imported into the Isolation workflow'), "Error message for #{field} incorrect"
      #   end
      # end
      if value && value.present? && checks.include?(:bool) && %w[true false].exclude?(value.to_s.downcase)
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not an acceptable value"), "Error message for #{field} missing"
      end
      if value && value.present? && checks.include?(:date) && !value.instance_of?(Date) && value.match(/\d{4}-\d{2}-\d{2}/)
        begin
          Date.parse(value)
        rescue ArgumentError
          assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not a valid date"), "Error message for #{field} missing"
        end
      end
      if value && value.present? && checks.include?(:date) && !value.instance_of?(Date) && !value.match(/\d{4}-\d{2}-\d{2}/) && format == :saf
        generic_msg = "Value '#{value}' for '#{VALIDATION[field][:label]}' is not a valid date"
        if value.match?(%r{\d{2}/\d{2}/\d{4}})
          specific_msg = "#{generic_msg} due to ambiguity between 'MM/DD/YYYY' and 'DD/MM/YYYY', please use the 'YYYY-MM-DD' format instead"
          assert page.has_content?(specific_msg), "Error message for #{field} missing"
        else
          assert page.has_content?("#{generic_msg}, please use the 'YYYY-MM-DD' format"), "Error message for #{field} missing"
        end
      end
      if value && value.present? && checks.include?(:phone) && Phonelib.parse(value, 'US').full_e164.nil?
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not a valid phone number"), "Error message for #{field} missing"
      end
      if value && value.present? && checks.include?(:state) && VALID_STATES.exclude?(value) && STATE_ABBREVIATIONS[value.to_s.upcase.to_sym].nil?
        assert page.has_content?("'#{value}' is not a valid state for '#{VALIDATION[field][:label]}'"), "Error message for #{field} missing"
      end
      if value && value.present? && checks.include?(:sex) && %(Male Female Unknown M F).exclude?(value.to_s.capitalize)
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not an acceptable value"),
               "Error message for #{field} missing"
      end
      if value && value.present? && checks.include?(:email) && !ValidEmail2::Address.new(value).valid?
        assert page.has_content?("Value '#{value}' for '#{VALIDATION[field][:label]}' is not a valid Email Address"), "Error message for #{field} missing"
      end
    elsif field == :jurisdiction_path
      return unless value && value.present?

      jurisdiction = Jurisdiction.where(path: value).first
      if jurisdiction.nil?
        if Jurisdiction.where(name: value).empty?
          assert page.has_content?("'#{value}' is not valid for 'Full Assigned Jurisdiction Path'"), "Error message for #{field} missing"
        else
          msg = "'#{value}' is not valid for 'Full Assigned Jurisdiction Path', please provide the full path instead of just the name"
          assert page.has_content?(msg), "Error message for #{field} missing"
        end
      else
        unless jurisdiction.subtree_ids.include?(jurisdiction[:id])
          msg = "'#{value}' is not valid for 'Full Assigned Jurisdiction Path' because you do not have permission to import into it"
          assert page.has_content?(msg), "Error message for #{field} missing"
        end
      end
    elsif field == :assigned_user
      return unless value && value.present? && !value.to_i.between?(1, 999_999)

      msg = "Value '#{value}' for 'Assigned User' is not valid, acceptable values are numbers between 1-999999"
      assert page.has_content?(msg), "Error message for #{field} missing"
    end
  end

  def verify_laboratory(patient, data)
    laboratory = Laboratory.where(
      patient_id: patient.id,
      lab_type: data[0].to_s,
      specimen_collection: data[1],
      report: data[2],
      result: data[3].to_s
    )
    assert laboratory.exists?, "Lab result for patient: #{patient.first_name} #{patient.last_name} not found"
  end

  def verify_vaccine(patient, data)
    vaccine = Vaccine.where(
      patient_id: patient.id,
      group_name: NORMALIZED_ENUMS[:group_name][normalize_enum_field_value(data[0])],
      product_name: NORMALIZED_ENUMS[:product_name][normalize_enum_field_value(data[1])],
      administration_date: data[2],
      dose_number: NORMALIZED_ENUMS[:dose_number][normalize_enum_field_value(data[3])],
      notes: data[4]
    )
    assert vaccine.exists?, "Vaccination for patient: #{patient.first_name} #{patient.last_name} not found"
  end

  def verify_existence(element, label, value, index)
    assert element.has_content?("#{label}:#{value && value != '' ? ' ' + value.to_s : ''}"), "#{label} should be #{value} in row #{index + 2}"
  end

  def epi_x_val(row, field)
    value = row[ImportExportConstants::EPI_X_FIELDS.index(field)]
    return nil if value.blank?

    value = Date.strptime(value, '%m/%d/%Y') if %i[date_of_birth date_of_departure].include?(field)
    value = Date.strptime(value, '%b %d %Y') if field == :date_of_arrival
    value
  end

  def saf_val(row, field)
    row[ImportExportConstants::SARA_ALERT_FORMAT_FIELDS.index(field)]
  end

  def displayed_epi_x_val(row, field)
    value = row[ImportExportConstants::EPI_X_FIELDS.index(field)]
    return nil if value.blank?

    value = Date.strptime(value, '%m/%d/%Y').strftime('%m/%d/%Y') if %i[date_of_birth date_of_departure].include?(field)
    value = Date.strptime(value, '%b %d %Y').strftime('%m/%d/%Y') if field == :date_of_arrival
    value = format_phone_number(value) if %i[primary_telephone secondary_telephone].include?(field)
    value
  end

  def displayed_saf_val(row, field)
    value = row[ImportExportConstants::SARA_ALERT_FORMAT_FIELDS.index(field)]
    return nil if value.blank?

    if %i[date_of_birth date_of_departure date_of_arrival].include?(field)
      value = value.instance_of?(String) ? Date.parse(value).strftime('%m/%d/%Y') : value.strftime('%m/%d/%Y')
    end
    value = format_phone_number(value&.to_s) if %i[primary_telephone secondary_telephone].include?(field)
    value
  end

  def normalize_state_field(value)
    value ? VALID_STATES.include?(value) ? value : STATE_ABBREVIATIONS[value.upcase.to_sym] : nil
  end

  def normalize_bool_field(value)
    %w[true false].include?(value.to_s.downcase) ? value.to_s.casecmp('true').zero? : nil
  end

  def get_xlsx(file_name)
    Roo::Spreadsheet.open(file_fixture(file_name).to_s)
  end
end
