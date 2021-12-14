# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../../../lib/system_test_utils'

class PublicHealthMonitoringImportVerifier < ApplicationSystemTestCase
  include ExportHelper
  include PatientHelper
  @@system_test_utils = SystemTestUtils.new(nil)

  TELEPHONE_FIELDS = %i[primary_telephone secondary_telephone alternate_primary_telephone alternate_secondary_telephone].freeze
  TELEPHONE_TYPE_FIELDS = %i[primary_telephone_type secondary_telephone_type alternate_primary_telephone_type alternate_secondary_telephone_type].freeze
  BOOL_FIELDS = %i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander race_other race_unknown
                   race_refused_to_answer interpretation_required contact_of_known_case travel_to_affected_country_or_area
                   was_in_health_care_facility_with_known_cases laboratory_personnel healthcare_personnel crew_on_passenger_or_cargo_flight
                   member_of_a_common_exposure_cohort].freeze
  STATE_FIELDS = %i[address_state foreign_monitored_address_state additional_planned_travel_destination_state].freeze
  MONITORED_ADDRESS_FIELDS = %i[monitored_address_line_1 monitored_address_city monitored_address_state monitored_address_line_2 monitored_address_zip].freeze
  # TODO: when workflow specific case status validation re-enabled: take out 'case_status'
  ISOLATION_FIELDS = %i[symptom_onset extended_isolation case_status].freeze
  ENUM_FIELDS = %i[ethnicity contact_type preferred_contact_method primary_telephone_type secondary_telephone_type alternate_contact_type
                   alternate_preferred_contact_method alternate_preferred_contact_time alternate_primary_telephone_type alternate_secondary_telephone_type
                   additional_planned_travel_type exposure_risk_assessment monitoring_plan case_status].freeze
  TIME_FIELDS = %i[preferred_contact_time].freeze
  RISK_FACTOR_FIELDS = %i[contact_of_known_case was_in_health_care_facility_with_known_cases].freeze
  # TODO: when workflow specific case status validation re-enabled: uncomment
  # WORKFLOW_SPECIFIC_FIELDS = %i[case_status].freeze
  NON_IMPORTED_PATIENT_FIELDS = %i[full_status
                                   lab_1_type lab_1_specimen_collection lab_1_report lab_1_result
                                   lab_2_type lab_2_specimen_collection lab_2_report lab_2_result
                                   vaccine_1_group_name vaccine_1_product_name vaccine_1_administration_date vaccine_1_dose_number vaccine_1_notes
                                   vaccine_2_group_name vaccine_2_product_name vaccine_2_administration_date vaccine_2_dose_number vaccine_2_notes
                                   vaccine_3_group_name vaccine_3_product_name vaccine_3_administration_date vaccine_3_dose_number vaccine_3_notes
                                   cohort_1_type cohort_1_name cohort_1_location
                                   cohort_2_type cohort_2_name cohort_2_location].freeze
  ADDRESS_FIELDS = %i[address_line_1 address_city address_zip address_line_2].freeze

  IMPORT_PAGE_FIELD_LABELS = {
    user_defined_id_statelocal: 'State/Local ID',
    user_defined_id_cdc: 'CDC ID',
    first_name: 'First Name',
    last_name: 'Last Name',
    date_of_birth: 'DOB',
    primary_language: 'Language',
    flight_or_vessel_number: 'Flight or Vessel Number',
    address_line_1: 'Home Address Line 1',
    address_city: 'Home Town/City',
    address_state: 'Home State',
    address_zip: 'Home Zip',
    monitored_address_line_1: 'Monitored Address Line 1',
    monitored_address_city: 'Monitored Town/City',
    monitored_address_state: 'Monitored State',
    monitored_address_zip: 'Monitored Zip',
    primary_telephone_type: 'Phone Number 1',
    secondary_telephone_type: 'Phone Number 2',
    email: 'Email',
    potential_exposure_location: 'Exposure Location',
    date_of_departure: 'Date of Departure',
    contact_of_known_case: 'Close Contact w/ Known Case',
    was_in_health_care_facility_with_known_cases: 'Was in HC Fac. w/ Known Cases'
  }.freeze

  IMPORT_PAGE_DISPLAYED_FIELDS = {
    saf: %i[user_defined_id_statelocal user_defined_id_cdc first_name last_name date_of_birth primary_language flight_or_vessel_number address_line_1
            address_city address_state address_zip monitored_address_line_1 monitored_address_city monitored_address_state monitored_address_zip
            primary_telephone secondary_telephone email potential_exposure_location date_of_departure contact_of_known_case
            was_in_health_care_facility_with_known_cases],
    epix: %i[user_defined_id_cdc first_name last_name date_of_birth flight_or_vessel_number monitored_address_line_1 monitored_address_city
             monitored_address_state primary_telephone secondary_telephone email date_of_departure],
    epix_domestic: %i[address_line_1 address_city address_state address_zip],
    sdx: %i[]
  }.freeze

  def verify_import(import_format, jurisdiction, workflow, file_name, rejects, accept_duplicates)
    sheet = get_xlsx(file_name).sheet(0)

    # verify info on import page
    find('.modal-body').all('div.card-body').each_with_index do |card, index|
      row = sheet.row(index + 2)
      verify_saf_import_page_card(jurisdiction, workflow, card, index, row) if import_format == :saf
      verify_epix_import_page_card(jurisdiction, workflow, card, index, row) if import_format == :epix
      verify_sdx_import_page_card(jurisdiction, workflow, card, index, row) if import_format == :sdx
    end

    # select monitorees to import
    if rejects.nil?
      click_on 'Import All'
      find(:css, '.confirm-dialog').find(:css, '.form-check-input').set(true) if accept_duplicates
      click_on 'OK'
    else
      find('.modal-body').all('div.card-body').each_with_index do |card, index|
        if rejects.include?(index)
          card.find('button', text: 'Reject').click
        else
          card.find('button', text: 'Accept').click
        end
        sleep(0.01) # wait for UI to update after accepting or rejecting monitoree
      end
    end

    # verify import data
    rejects = [] if rejects.nil?
    sleep(2) # wait for db write
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      verify_saf_import_monitoree(jurisdiction, workflow, rejects, accept_duplicates, row, row_num) if import_format == :saf
      verify_epix_import_monitoree(jurisdiction, workflow, rejects, accept_duplicates, row, row_num) if import_format == :epix
      verify_sdx_import_monitoree(jurisdiction, workflow, rejects, accept_duplicates, row, row_num) if import_format == :sdx
    end
  end

  def verify_invalid_file_error(import_format)
    find('.modal-body').assert_text "Please make sure that your import file is a .#{import_format == :saf ? 'xlsx' : 'csv'} file."
  end

  def verify_invalid_format_error(import_format)
    find('.modal-body').assert_text "Please make sure that .#{import_format == :saf ? 'xlsx' : 'csv'} import file is formatted in accordance with the "\
                                    'formatting guidance.'
  end

  def verify_invalid_headers_error(import_format)
    case import_format
    when :saf
      find('.modal-body').assert_text 'Please make sure to use the latest format specified by the Sara Alert Format guidance doc.'
    when :epix
      find('.modal-body').assert_text 'Please make sure to use the latest Epi-X format.'
    when :sdx
      find('.modal-body').assert_text 'Please make sure to use the latest SDX format.'
    end
  end

  def verify_invalid_monitorees_error
    find('.modal-body').assert_text 'File must contain at least one monitoree to import.'
  end

  def verify_invalid_fields_error(import_format, jurisdiction, workflow, file_name)
    sheet = get_xlsx(file_name).sheet(0)
    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      sleep(2)
      row.each_with_index do |value, index|
        verify_invalid_fields_validation_messages(import_format, jurisdiction, workflow, IMPORT_FORMATS[import_format][:fields][index], value, row_num)
      end
    end
  end

  def verify_saf_import_page_card(jurisdiction, workflow, card, index, row)
    IMPORT_PAGE_DISPLAYED_FIELDS[:saf].each do |field|
      verify_existence(card, IMPORT_PAGE_FIELD_LABELS[field], displayed_saf_val(row, field), index) unless displayed_saf_val(row, field) == 'Self'
    end

    if saf_val(row, :jurisdiction_path)
      assert card.has_content?("This #{workflow == :exposure ? 'monitoree' : 'case'} will be imported into '#{saf_val(row, :jurisdiction_path)}'"),
             "Jurisdiction path for row #{index + 1} should be #{saf_val(row, :assigned_user)}"
    end
    if saf_val(row, :assigned_user)
      assert card.has_content?("This #{workflow == :exposure ? 'monitoree' : 'case'} will be assigned to user '#{saf_val(row, :assigned_user)}'"),
             "Assigned user for row #{index + 1} should be #{saf_val(row, :assigned_user)}"
    end

    return unless jurisdiction.all_patients_excluding_purged
                              .where(first_name: saf_val(row, :first_name), middle_name: saf_val(row, :middle_name), last_name: :last_name).length > 1

    assert card.has_content?("Warning: This #{workflow == :exposure ? 'monitoree' : 'case'} already appears to exist in the system!")
  end

  def verify_epix_import_page_card(jurisdiction, workflow, card, index, row)
    fields = IMPORT_PAGE_DISPLAYED_FIELDS[:epix]
    country = displayed_epix_val(row, :foreign_address_country)
    fields += IMPORT_PAGE_DISPLAYED_FIELDS[:epix_domestic] if country.blank? || country.downcase.strip == 'united states'
    fields.each do |field|
      verify_existence(card, IMPORT_PAGE_FIELD_LABELS[field], displayed_epix_val(row, field), index)
    end

    return unless jurisdiction.all_patients_excluding_purged.where(first_name: epix_val(row, :first_name), last_name: epix_val(row, :last_name)).length > 1

    assert card.has_content?("Warning: This #{workflow == :exposure ? 'monitoree' : 'case'} already appears to exist in the system!")
  end

  def verify_sdx_import_page_card(jurisdiction, workflow, card, index, row)
    IMPORT_PAGE_DISPLAYED_FIELDS[:sdx].each do |field|
      verify_existence(card, IMPORT_PAGE_FIELD_LABELS[field], displayed_epix_val(row, field), index)
    end

    return unless jurisdiction.all_patients_excluding_purged.where(first_name: epix_val(row, :first_name), last_name: epix_val(row, :last_name)).length > 1

    assert card.has_content?("Warning: This #{workflow == :exposure ? 'monitoree' : 'case'} already appears to exist in the system!")
  end

  def verify_saf_import_monitoree(jurisdiction, workflow, rejects, accept_duplicates, row, row_num)
    # find patient and any duplicates
    patients = jurisdiction.all_patients_excluding_purged.where(first_name: saf_val(row, :first_name)).where(middle_name: saf_val(row, :middle_name))
                           .where(last_name: saf_val(row, :last_name), date_of_birth: saf_val(row, :date_of_birth))
    patient = patients.where('created_at > ?', 1.minute.ago)[0]
    duplicate = patients.where('created_at < ?', 1.minute.ago).exists?

    # patient should not exist if duplicate is rejected
    nil_msg = "Patient should not be found in db: #{saf_val(row, :first_name)} #{saf_val(row, :middle_name)} #{saf_val(row, :last_name)} in row #{row_num}"
    assert_nil(patient, nil_msg) && return if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)

    # patient should exist
    assert_not_nil(patient, "Patient not found in db: #{saf_val(row, :first_name)} #{saf_val(row, :middle_name)} #{saf_val(row, :last_name)} in row #{row_num}")

    # verify individual fields
    assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_num}")
    SAF_FIELDS.each_with_index do |field, index|
      next if field.nil?

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
      elsif field == :continuous_exposure
        continuous_exposure_value = get_continuous_exposure_value(row[index].to_s, workflow)
        assert_equal(patient[field], continuous_exposure_value, err_msg)
      elsif field == :contact_type
        assert_equal(NORMALIZED_ENUMS[field][normalize_enum_field_value(row[index])].to_s.blank? ? 'Unknown' : row[index].to_s, patient[field].to_s, err_msg)
      elsif ENUM_FIELDS.include?(field)
        assert_equal(NORMALIZED_ENUMS[field][normalize_enum_field_value(row[index])].to_s, patient[field].to_s, err_msg)
      elsif TIME_FIELDS.include?(field)
        assert_equal(NORMALIZED_INVERTED_TIME_OPTIONS[normalize_enum_field_value(row[index])].to_s, patient[field].to_s, err_msg)
      elsif NON_IMPORTED_PATIENT_FIELDS.exclude?(field)
        assert_equal(row[index].to_s, patient[field].to_s, err_msg)
      end
    end

    # verify associated records
    verify_laboratory(patient, row[87..90], 1) if row[87..90].filter(&:present?).any?
    verify_laboratory(patient, row[91..94], 2) if row[91..94].filter(&:present?).any?
    verify_vaccine(patient, row[102..106], 1) if row[102..106].filter(&:present?).any?
    verify_vaccine(patient, row[107..111], 2) if row[107..111].filter(&:present?).any?
    verify_vaccine(patient, row[114..118], 3) if row[114..118].filter(&:present?).any?
    verify_cohort(patient, row[132..134], 1) if row[132..134].filter(&:present?).any?
    verify_cohort(patient, row[135..137], 2) if row[135..137].filter(&:present?).any?
  end

  def verify_epix_import_monitoree(jurisdiction, workflow, rejects, accept_duplicates, row, row_num)
    # find patient and any duplicates
    patients = jurisdiction.all_patients_excluding_purged.where(first_name: epix_val(row, :first_name))
                           .where(last_name: epix_val(row, :last_name)).where(date_of_birth: epix_val(row, :date_of_birth))
    patient = patients.where('created_at > ?', 1.minute.ago)[0]
    duplicate = patients.where('created_at < ?', 1.minute.ago).exists?

    # patient should not exist if duplicate is rejected
    nil_msg = "Patient should not be found in db: #{epix_val(row, :first_name)} #{epix_val(row, :last_name)} in row #{row_num}"
    assert_nil(patient, nil_msg) && return if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)

    # patient should exist
    assert_not_nil(patient, "Patient not found in db: #{epix_val(row, :first_name)} #{epix_val(row, :last_name)} in row #{row_num}")

    # verify individual fields
    assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_num}")
    international_address = epix_val(row, :foreign_address_country).present? && epix_val(row, :foreign_address_country)&.strip&.downcase != 'united states'
    EPIX_FIELDS.each_with_index do |field, index|
      err_msg = "#{field} mismatch in row #{row_num}"
      # import primary_telephone before secondary_telephone
      if field == :primary_telephone && row[EPIX_FIELDS.index(:primary_telephone)].blank?
        assert_equal(Phonelib.parse(row[EPIX_FIELDS.index(:secondary_telephone)], 'US').full_e164, patient[:primary_telephone].to_s, err_msg)
      elsif field == :secondary_telephone && row[EPIX_FIELDS.index(:primary_telephone)].blank?
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
      elsif international_address && ADDRESS_FIELDS.include?(field)
        assert_equal(row[index].to_s, patient[ImportController::FOREIGN_ADDRESS_MAPPINGS[field]].to_s, err_msg)
      elsif international_address && field == :address_state
        assert_equal(normalize_state_field(row[index].to_s), patient[ImportController::FOREIGN_ADDRESS_MAPPINGS[field]].to_s, err_msg)
      # normalize state fields
      elsif field == :address_state || (field == :monitored_address_state && row[index].present?)
        assert_equal(normalize_state_field(row[index].to_s).to_s, patient[field].to_s, err_msg)
      # these fields come from multiple columns
      elsif %i[travel_related_notes port_of_entry_into_usa].include?(field)
        assert_includes(patient[field].to_s, row[index].to_s, err_msg)
      # format dates
      elsif %i[date_of_birth date_of_departure symptom_onset].include?(field)
        assert_equal(row[index].present? ? Date.strptime(row[index], '%m/%d/%Y').to_s : '', patient[field].to_s, err_msg)
      elsif field == :date_of_arrival
        assert_equal(row[index].present? ? Date.strptime(row[index], '%b %d %Y').to_s : '', patient[field].to_s, err_msg)
      elsif !field.nil?
        assert_equal(row[index].to_s, patient[field].to_s, err_msg)
      end
    end
  end

  def verify_sdx_import_monitoree(jurisdiction, workflow, rejects, accept_duplicates, row, row_num)
    # find patient and any duplicates
    patients = jurisdiction.all_patients_excluding_purged.where(first_name: sdx_val(row, :first_name))
                           .where(last_name: sdx_val(row, :last_name)).where(date_of_birth: sdx_val(row, :date_of_birth))
    patient = patients.where('created_at > ?', 1.minute.ago)[0]
    duplicate = patients.where('created_at < ?', 1.minute.ago).exists?

    # patient should not exist if duplicate is rejected
    nil_msg = "Patient should not be found in db: #{sdx_val(row, :first_name)} #{sdx_val(row, :last_name)} in row #{row_num}"
    assert_nil(patient, nil_msg) && return if rejects.include?(row_num - 2) || (duplicate && !accept_duplicates)

    # patient should exist
    assert_not_nil(patient, "Patient not found in db: #{sdx_val(row, :first_name)} #{sdx_val(row, :last_name)} in row #{row_num}")

    # verify individual fields
    assert_equal(workflow == :isolation, patient[:isolation], "incorrect workflow in row #{row_num}")
    SDX_FIELDS.each_with_index do |field, index|
      err_msg = "#{field} mismatch in row #{row_num}"
      if [nil, 'N/A'].include?(row[index])
        if %i[travel_related_notes flight_or_vessel_carrier flight_or_vessel_number].include?(field)
          assert_not_includes(patient[field].to_s, row[index].to_s, err_msg) if row[index].present?
        else
          assert_nil(patient[field], err_msg)
        end
      elsif TELEPHONE_FIELDS.include?(field)
        phone = Phonelib.parse(row[index], 'US')
        if phone.full_e164.present? && phone.full_e164.sub(/^\+1+/, '').length == 10
          assert_equal(Phonelib.parse(row[index], 'US').full_e164, patient[field].to_s, err_msg)
        elsif field == :alternate_primary_telephone
          assert_equal(row[index], patient[:alternate_international_telephone])
        elsif field == :primary_telephone
          assert_equal(row[index], patient[:international_telephone])
        elsif field == :secondary_telephone
          assert_includes(patient[:exposure_notes].to_s, "#{SDX_HEADERS[index]}: #{row[index]}")
        end
      elsif TELEPHONE_TYPE_FIELDS.include?(field)
        if NORMALIZED_ENUMS[field].key?(normalize_enum_field_value(row[index]))
          assert_equal(NORMALIZED_ENUMS[field][normalize_enum_field_value(row[index])], patient[field].to_s, err_msg)
        else
          assert_nil(patient[field])
        end
      elsif BOOL_FIELDS.include?(field)
        assert_equal(normalize_bool_field(row[index]).to_s, patient[field].to_s, err_msg)
      elsif STATE_FIELDS.include?(field) || (field == :monitored_address_state && !row[index].nil?)
        assert_equal(normalize_state_field(row[index].to_s).to_s, patient[field].to_s, err_msg)
      elsif field == :sex && row[index].present?
        assert_equal(SEX_ABBREVIATIONS[row[index].upcase.to_sym] || row[index]&.downcase&.capitalize, patient[field].to_s, err_msg)
      # these fields come from multiple columns
      elsif %i[travel_related_notes flight_or_vessel_carrier flight_or_vessel_number].include?(field)
        assert_includes(patient[field].to_s, "#{SDX_HEADERS[index]}: #{row[index]}", err_msg)
      elsif field == :exposure_notes
        assert_includes(patient[field].to_s, "#{SDX_HEADERS[index]}: #{Date.strptime(row[index], '%m%d%Y')}", err_msg)
      # format dates
      elsif %i[date_of_arrival date_of_departure date_of_birth].include?(field)
        assert_equal(Date.strptime(row[index], '%m%d%Y').to_s, patient[field].to_s, err_msg)
      elsif field == :gender_identity
        normalized_value = row[index]&.downcase&.gsub(/[ -.]/, '')
        if SDX_MAPPINGS[:gender_identity].key?(normalized_value)
          assert_equal(SDX_MAPPINGS[:gender_identity][normalized_value], patient[:gender_identity])
          assert_equal(SDX_MAPPINGS[:sex][normalized_value], patient[:sex])
        else
          assert_nil(patient[:gender_identity])
          assert_nil(patient[:sex])
        end
      elsif field == :alternate_contact_type
        normalized_value = row[index]&.downcase&.gsub(/[ -.]/, '')
        if SDX_MAPPINGS[:alternate_contact_type].key?(normalized_value)
          assert_equal(SDX_MAPPINGS[:alternate_contact_type][normalized_value], pattient[:alternate_contact_type])
        else
          assert_nil(patient[:alternate_contact_type])
        end
      elsif field == :alternate_contact_name
        assert_includes(patient[field].to_s, row[index], err_msg)
      elsif !field.nil?
        assert_equal(row[index].to_s, patient[field].to_s, err_msg)
      end
    end
  end

  def verify_invalid_fields_validation_messages(import_format, jurisdiction, workflow, field, value, row_num)
    # ignore isolation specific fields for exposure workflow
    return if workflow != :isolation && ISOLATION_FIELDS.include?(field)

    # no validation if field is blank
    return if value.blank?

    err_msg = "Error message for #{field} missing on row #{row_num} (value: #{value})"

    if VALIDATION[field]
      field_label = VALIDATION[field][:label]
      header_label = IMPORT_FORMATS[import_format][:headers][IMPORT_FORMATS[import_format][:fields].index(field)]
      checks = VALIDATION[field][:checks]

      if checks.include?(:enum) && !NORMALIZED_ENUMS[field].key?(normalize_enum_field_value(value))
        return if import_format == :sdx # field is ignored instead of strictly validated

        assert page.has_content?("Value '#{value}' for '#{header_label}' is not an acceptable value"), err_msg
      end
      if checks.include?(:bool) && %w[true false].exclude?(value.to_s.downcase)
        assert page.has_content?("Value '#{value}' for '#{field_label}' is not an acceptable value"), err_msg
      end
      if checks.include?(:date) && !value.instance_of?(Date) && value.match(/\d{4}-\d{2}-\d{2}/)
        begin
          Date.parse(value)
        rescue ArgumentError
          assert page.has_content?("Value '#{value}' for '#{header_label}' is not a valid date") ||
                 page.has_content?("'#{value}' is not a valid date for '#{header_label}'"), err_msg
        end
      end
      if checks.include?(:date) && !value.instance_of?(Date) && !value.match(/\d{4}-\d{2}-\d{2}/) && import_format == :saf
        generic_msg = "Value '#{value}' for '#{header_label}' is not a valid date"
        if value.match?(%r{\d{2}/\d{2}/\d{4}})
          assert page.has_content?("#{generic_msg} due to ambiguity between 'MM/DD/YYYY' and 'DD/MM/YYYY', please use the 'YYYY-MM-DD' format instead"), err_msg
        else
          assert page.has_content?("#{generic_msg}, please use the 'YYYY-MM-DD' format"), err_msg
        end
      end
      if checks.include?(:phone) && Phonelib.parse(value, 'US').full_e164.nil?
        assert page.has_content?("Value '#{value}' for '#{header_label}' is not a valid phone number"), err_msg
      end
      if checks.include?(:state) && VALID_STATES.exclude?(value) && STATE_ABBREVIATIONS[value.to_s.upcase.to_sym].nil?
        assert page.has_content?("'#{value}' is not a valid state for '#{field_label}'"), err_msg
      end
      if checks.include?(:sex) && %(Male Female Unknown M F).exclude?(value.to_s.capitalize)
        assert page.has_content?("Value '#{value}' for '#{field_label}' is not an acceptable value"), err_msg
      end
      if checks.include?(:email) && !ValidEmail2::Address.new(value).valid?
        assert page.has_content?("Value '#{value}' for '#{field_label}' is not a valid Email Address"), err_msg
      end
      # TODO: Un-comment when required fields are to be checked upon import
      # if checks.include?(:required) && (!value || value.blank?)
      #   assert page.has_content? "Required field '#{header_label}' is missing", err_msg
      # end
      # TODO: when workflow specific case status validation re-enabled: uncomment
      # if WORKFLOW_SPECIFIC_FIELDS.include?(field)
      #   if workflow == :exposure && !NORMALIZED_EXPOSURE_ENUMS[field].keys.include?(normalize_enum_field_value(value))
      #     assert page.has_content? 'for monitorees imported into the Exposure workflow', err_msg
      #   elsif workflow == :isolation && !NORMALIZED_ISOLATION_ENUMS[field].keys.include?(normalize_enum_field_value(value))
      #     assert page.has_content? 'for cases imported into the Isolation workflow', err_msg
      #   end
      # end
    elsif field == :jurisdiction_path
      return unless value && value.present?

      jurisdiction = Jurisdiction.find_by(path: value)
      generic_msg = "'#{value}' is not valid for 'Full Assigned Jurisdiction Path'"
      if jurisdiction.nil?
        assert page.has_content?("#{generic_msg}#{Jurisdiction.exists?(name: value) ? ', please provide the full path instead of just the name' : ''}"), err_msg
      elsif jurisdiction.subtree_ids.include?(jurisdiction[:id])
        assert page.has_content?("#{generic_msg} because you do not have permission to import into it"), err_msg
      end
    elsif field == :assigned_user && !value.to_i.between?(1, 999_999)
      assert page.has_content?("Value '#{value}' for 'Assigned User' is not valid, acceptable values are numbers between 1-999999"), err_msg
    end
  end

  def verify_laboratory(patient, data, num)
    laboratory = Laboratory.where(
      patient_id: patient.id,
      lab_type: data[0].to_s,
      specimen_collection: data[1],
      report: data[2],
      result: data[3].to_s
    )
    assert laboratory.exists?, "Lab result #{num} for patient: #{patient.first_name} #{patient.last_name} not found"
  end

  def verify_vaccine(patient, data, num)
    vaccine = Vaccine.where(
      patient_id: patient.id,
      group_name: NORMALIZED_ENUMS[:group_name][normalize_enum_field_value(data[0])],
      product_name: NORMALIZED_ENUMS[:product_name][normalize_enum_field_value(data[1])],
      administration_date: data[2],
      dose_number: NORMALIZED_ENUMS[:dose_number][normalize_enum_field_value(data[3])],
      notes: data[4]
    )
    assert vaccine.exists?, "Vaccination #{num} for patient: #{patient.first_name} #{patient.last_name} not found"
  end

  def verify_cohort(patient, data, num)
    cohort = CommonExposureCohort.where(
      patient_id: patient.id,
      cohort_type: data[0].to_s,
      cohort_name: data[1].to_s,
      cohort_location: data[2].to_s
    )
    assert cohort.exists?, "Common Exposure Cohort #{num} for patient: #{patient.first_name} #{patient.last_name} not found"
  end

  def verify_existence(element, label, value, index)
    assert element.has_content?("#{label}:#{value && value != '' ? ' ' + value.to_s : ''}"), "#{label} should be #{value} in row #{index + 2}"
  end

  def saf_val(row, field)
    row[ImportExportConstants::SAF_FIELDS.index(field)]
  end

  def epix_val(row, field)
    value = row[ImportExportConstants::EPIX_FIELDS.index(field)]
    return nil if value.blank?

    value = Date.strptime(value, '%m/%d/%Y') if %i[date_of_birth date_of_departure].include?(field)
    value = Date.strptime(value, '%b %d %Y') if field == :date_of_arrival
    value
  end

  def sdx_val(row, field)
    value = row[ImportExportConstants::SDX_FIELDS.index(field)]
    return nil if value.blank?

    value = Date.strptime(value, '%m%d%Y') if %i[date_of_arrival date_of_departure date_of_birth].include?(field)
    value
  end

  def displayed_saf_val(row, field)
    value = row[ImportExportConstants::SAF_FIELDS.index(field)]
    return nil if value.blank?

    if %i[date_of_birth date_of_departure date_of_arrival].include?(field)
      value = value.instance_of?(String) ? Date.parse(value).strftime('%m/%d/%Y') : value.strftime('%m/%d/%Y')
    end
    value = value&.to_s&.downcase if %i[contact_of_known_case was_in_health_care_facility_with_known_cases].include?(field)
    value = format_phone_number(value&.to_s) if %i[primary_telephone secondary_telephone].include?(field)
    value = normalize_state_field(value) if %i[address_state monitored_address_state].include?(field)
    value
  end

  def displayed_epix_val(row, field)
    value = row[ImportExportConstants::EPIX_FIELDS.index(field)]
    return nil if value.blank?

    value = Date.strptime(value, '%m/%d/%Y').strftime('%m/%d/%Y') if %i[date_of_birth date_of_departure].include?(field)
    value = Date.strptime(value, '%b %d %Y').strftime('%m/%d/%Y') if field == :date_of_arrival
    value = format_phone_number(value) if %i[primary_telephone secondary_telephone].include?(field)
    value = normalize_state_field(value) if %i[address_state monitored_address_state].include?(field)
    value = 'Unknown' if field == :contact_type
    value
  end

  def displayed_sdx_val(row, field)
    value = row[ImportExportConstants::SDX_FIELDS.index(field)]
    return nil if value.blank?

    value = Date.strptime(value, '%m/%d/%y').strftime('%m/%d/%Y') if %i[date_of_arrival date_of_departure date_of_birth].include?(field)
    value = format_phone_number(value) if %i[primary_telephone secondary_telephone].include?(field)
    value = normalize_state_field(value) if %i[address_state monitored_address_state].include?(field)
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

  def get_continuous_exposure_value(value, workflow)
    return false if workflow == :isolation || value.blank?

    normalize_bool_field(value)
  end
end
