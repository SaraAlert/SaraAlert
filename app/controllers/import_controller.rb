# frozen_string_literal: true

require 'roo'

# ImportController: for importing subjects from other formats
class ImportController < ApplicationController
  include ImportExportHelper

  before_action :authenticate_user!

  def index
    redirect_to(root_url) && return unless current_user.can_import?
  end

  def error
    @error_msg = params[:error_details]
  end

  def download_guidance
    send_file(
      "#{Rails.root}/public/sara_alert_comprehensive_monitoree.xlsx",
      filename: 'sara_alert_comprehensive_monitoree.xlsx',
      type: 'application/vnd.ms-excel'
    )
  end

  def import
    redirect_to(root_url) && return unless current_user.can_import?

    redirect_to(root_url) && return unless params.permit(:workflow)[:workflow] == 'exposure' || params.permit(:workflow)[:workflow] == 'isolation'

    redirect_to(root_url) && return unless params.permit(:format)[:format] == 'epix' || params.permit(:format)[:format] == 'comprehensive_monitorees'

    workflow = params.permit(:workflow)[:workflow].to_sym
    format = params.permit(:format)[:format].to_sym

    @errors = []
    @patients = []

    # Load and parse patient import excel
    begin
      xlsx = Roo::Excelx.new(params[:file].tempfile.path, file_warning: :ignore)
      validate_headers(format, xlsx.sheet(0).row(1))

      xlsx.sheet(0).each_with_index do |row, index|
        next if index.zero? # Skip headers

        patient = epix_row(row, index, workflow) if format == :epix
        patient = comprehensive_monitorees_row(row, index, workflow) if format == :comprehensive_monitorees
        patient[:isolation] = workflow == :isolation

        @patients << patient
      rescue ValidationError => e
        @errors << e&.message || "Unknown error on row #{index}"
      rescue StandardError => e
        @errors << e&.message || 'Unexpected error'
      end
    rescue Zip::Error
      # Roo throws this if the file is not an excel file
      @errors << 'File Error: Please make sure that your import file is a .xlsx file.'
    rescue ArgumentError, NoMethodError
      # Roo throws this error when the columns are not what we expect
      @errors << 'Format Error: Please make sure that .xlsx import file is formatted in accordance with the formatting guidance.'
    rescue StandardError => e
      # This is a catch all for any other unexpected error
      @errors << "Unexpected Error: '#{e&.message}' Please make sure that .xlsx import file is formatted in accordance with the formatting guidance."
    end
  end

  def epix_row(row, row_num, workflow)
    sex = 'Male' if row[13] == 'M'
    sex = 'Female' if row[13] == 'F'
    {
      user_defined_id_statelocal: row[0],
      flight_or_vessel_number: row[1],
      user_defined_id_cdc: row[4],
      primary_language: row[7],
      date_of_arrival: validate_field(:date_of_arrival, row[8], row_num),
      port_of_entry_into_usa: row[9],
      last_name: validate_field(:last_name, row[10], row_num),
      first_name: validate_field(:first_name, row[11], row_num),
      date_of_birth: validate_field(:date_of_birth, row[12], row_num),
      sex: sex,
      address_line_1: validate_field(:address_line_1, row[16], row_num),
      address_city: validate_field(:address_city, row[17], row_num),
      address_state: validate_field(:address_state, row[18], row_num),
      address_zip: validate_field(:address_zip, row[19], row_num),
      monitored_address_line_1: row[20],
      monitored_address_city: row[21],
      monitored_address_state: validate_field(:monitored_address_state, row[22], row_num),
      monitored_address_zip: row[23],
      primary_telephone: validate_field(:primary_telephone, row[28], row_num),
      secondary_telephone: validate_field(:secondary_telephone, row[29], row_num),
      email: row[30],
      potential_exposure_location: row[35],
      potential_exposure_country: row[35],
      date_of_departure: row[36],
      contact_of_known_case: !row[41].blank?,
      was_in_health_care_facility_with_known_cases: !row[42].blank?,
      appears_to_be_duplicate: current_user.viewable_patients.matches(row[11], row[10], sex, row[12]).exists?,
      isolation: workflow == :isolation
    }
  end

  def comprehensive_monitorees_row(row, row_num, workflow)
    lab_results = []
    lab_results.push(lab_result(row[87..90], row_num)) if !row[87].blank? || !row[88].blank? || !row[89].blank? || !row[90].blank?
    lab_results.push(lab_result(row[91..94], row_num)) if !row[91].blank? || !row[92].blank? || !row[93].blank? || !row[94].blank?
    parsed_row = {
      first_name: validate_field(:first_name, row[0], row_num),
      middle_name: row[1],
      last_name: validate_field(:last_name, row[2], row_num),
      date_of_birth: validate_field(:date_of_birth, row[3], row_num),
      sex: validate_field(:sex, row[4], row_num),
      white: validate_field(:white, row[5], row_num),
      black_or_african_american: validate_field(:black_or_african_american, row[6], row_num),
      american_indian_or_alaska_native: validate_field(:american_indian_or_alaska_native, row[7], row_num),
      asian: validate_field(:asian, row[8], row_num),
      native_hawaiian_or_other_pacific_islander: validate_field(:native_hawaiian_or_other_pacific_islander, row[9], row_num),
      ethnicity: validate_field(:ethnicity, row[10], row_num),
      primary_language: row[11],
      secondary_language: row[12],
      interpretation_required: validate_field(:interpretation_required, row[13], row_num),
      nationality: row[14],
      user_defined_id_statelocal: row[15],
      user_defined_id_cdc: row[16],
      user_defined_id_nndss: row[17],
      address_line_1: validate_field(:address_line_1, row[18], row_num),
      address_city: validate_field(:address_city, row[19], row_num),
      address_state: validate_field(:address_state, row[20], row_num),
      address_line_2: row[21],
      address_zip: validate_field(:address_zip, row[22], row_num),
      address_county: row[23],
      foreign_address_line_1: row[24],
      foreign_address_city: row[25],
      foreign_address_country: row[26],
      foreign_address_line_2: row[27],
      foreign_address_zip: row[28],
      foreign_address_line_3: row[29],
      foreign_address_state: row[30],
      monitored_address_line_1: row[31],
      monitored_address_city: row[32],
      monitored_address_state: validate_field(:monitored_address_state, row[33], row_num),
      monitored_address_line_2: row[34],
      monitored_address_zip: row[35],
      monitored_address_county: row[36],
      foreign_monitored_address_line_1: row[37],
      foreign_monitored_address_city: row[38],
      foreign_monitored_address_state: validate_field(:foreign_monitored_address_state, row[39], row_num),
      foreign_monitored_address_line_2: row[40],
      foreign_monitored_address_zip: row[41],
      foreign_monitored_address_county: row[42],
      preferred_contact_method: validate_field(:preferred_contact_method, row[43], row_num),
      primary_telephone: validate_field(:primary_telephone, row[44], row_num),
      primary_telephone_type: validate_field(:primary_telephone_type, row[45], row_num),
      secondary_telephone: validate_field(:secondary_telephone, row[46], row_num),
      secondary_telephone_type: validate_field(:secondary_telephone_type, row[47], row_num),
      preferred_contact_time: validate_field(:preferred_contact_time, row[48], row_num),
      email: row[49],
      port_of_origin: row[50],
      date_of_departure: validate_field(:date_of_departure, row[51], row_num),
      source_of_report: row[52],
      flight_or_vessel_number: row[53],
      flight_or_vessel_carrier: row[54],
      port_of_entry_into_usa: row[55],
      date_of_arrival: validate_field(:date_of_arrival, row[56], row_num),
      travel_related_notes: row[57],
      additional_planned_travel_type: validate_field(:additional_planned_travel_type, row[58], row_num),
      additional_planned_travel_destination: row[59],
      additional_planned_travel_destination_state: validate_field(:additional_planned_travel_destination_state, row[60], row_num),
      additional_planned_travel_destination_country: row[61],
      additional_planned_travel_port_of_departure: row[62],
      additional_planned_travel_start_date: validate_field(:additional_planned_travel_start_date, row[63], row_num),
      additional_planned_travel_end_date: validate_field(:additional_planned_travel_end_date, row[64], row_num),
      additional_planned_travel_related_notes: row[65],
      last_date_of_exposure: validate_field(:last_date_of_exposure, row[66], row_num),
      potential_exposure_location: row[67],
      potential_exposure_country: row[68],
      contact_of_known_case: validate_field(:contact_of_known_case, row[69], row_num),
      contact_of_known_case_id: row[70],
      travel_to_affected_country_or_area: validate_field(:travel_to_affected_country_or_area, row[71], row_num),
      was_in_health_care_facility_with_known_cases: validate_field(:was_in_health_care_facility_with_known_cases, row[72], row_num),
      was_in_health_care_facility_with_known_cases_facility_name: row[73],
      laboratory_personnel: validate_field(:laboratory_personnel, row[74], row_num),
      laboratory_personnel_facility_name: row[75],
      healthcare_personnel: validate_field(:healthcare_personnel, row[76], row_num),
      healthcare_personnel_facility_name: row[77],
      crew_on_passenger_or_cargo_flight: validate_field(:crew_on_passenger_or_cargo_flight, row[78], row_num),
      member_of_a_common_exposure_cohort: validate_field(:member_of_a_common_exposure_cohort, row[79], row_num),
      member_of_a_common_exposure_cohort_type: row[80],
      exposure_risk_assessment: validate_field(:exposure_risk_assessment, row[81], row_num),
      monitoring_plan: validate_field(:monitoring_plan, row[82], row_num),
      exposure_notes: row[83],
      symptom_onset: workflow == :isolation ? validate_field(:symptom_onset, row[85], row_num) : nil,
      case_status: workflow == :isolation ? validate_field(:case_status, row[86], row_num) : nil,
      appears_to_be_duplicate: current_user.viewable_patients.matches(row[0], row[2], row[4], row[3]).exists?,
      isolation: workflow == :isolation,
      laboratories: lab_results.empty? ? nil : lab_results
    }
    validate_required_primary_contact(parsed_row, row_num)
    parsed_row
  end

  def lab_result(data, row_num)
    {
      lab_type: data[0],
      specimen_collection: validate_field(:specimen_collection, data[1], row_num),
      report: validate_field(:report, data[2], row_num),
      result: data[3]
    }
  end

  private

  def validate_headers(format, row)
    expected_headers = COMPREHENSIVE_HEADERS if format == :comprehensive_monitorees
    expected_headers = EPI_X_HEADERS if format == :epix
    expected_headers.each_with_index do |field, index|
      raise ValidationError.new("Incorrect header for field #{field}", 1) if field != row[index]
    end
  end

  def validate_field(field, value, row_num)
    return unless VALIDATION[field]

    value = validate_required_field(field, value, row_num) if VALIDATION[field][:checks].include?(:required)
    value = validate_enum_field(field, value, row_num) if VALIDATION[field][:checks].include?(:enum)
    value = validate_bool_field(field, value, row_num) if VALIDATION[field][:checks].include?(:bool)
    value = validate_date_field(field, value, row_num) if VALIDATION[field][:checks].include?(:date)
    value = validate_phone_field(field, value, row_num) if VALIDATION[field][:checks].include?(:phone)
    value = validate_state_field(field, value, row_num) if VALIDATION[field][:checks].include?(:state)
    value
  end

  def validate_required_primary_contact(row, row_num)
    if row[:email].blank? && row[:preferred_contact_method] == 'E-mailed Web Link'
      raise ValidationError.new("Field 'Email' is required when Primary Contact Method is 'E-mailed Web Link'", row_num)
    end
    return unless row[:primary_telephone].blank? && (['SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].include? row[:preferred_contact_method])

    raise ValidationError.new("Field 'Primary Telephone' is required when Primary Contact Method is '#{row[:preferred_contact_method]}'", row_num)
  end

  def validate_required_field(field, value, row_num)
    raise ValidationError.new("Required field '#{VALIDATION[field][:label]}' is missing", row_num) if value.blank?

    value
  end

  def validate_enum_field(field, value, row_num)
    return value if value.blank? || VALID_ENUMS[field].include?(value)

    err_msg = "#{value} is not an acceptable value for field '#{VALIDATION[field][:label]}', acceptable values are: #{VALID_ENUMS[field].to_sentence}"
    raise ValidationError.new(err_msg, row_num)
  end

  def validate_bool_field(field, value, row_num)
    return value if value.blank?
    return (value.to_s.downcase == 'true') if %w[true false].include? value.to_s.downcase

    err_msg = "#{value} is not one of the accepted values for field '#{VALIDATION[field][:label]}', acceptable values are: 'True' and 'False'"
    raise ValidationError.new(err_msg, row_num)
  end

  def validate_date_field(field, value, row_num)
    return value if value.blank?
    return value if value.instance_of? Date

    begin
      Date.parse(value)
    rescue ArgumentError
      raise ValidationError.new("#{value} is not a valid date for field '#{VALIDATION[field][:label]}", row_num)
    end
  end

  def validate_phone_field(field, value, row_num)
    return value if value.blank?

    normalized_phone = Phonelib.parse(value, 'US').full_e164
    return normalized_phone if normalized_phone

    raise ValidationError.new("#{value} is not a valid phone number for field '#{VALIDATION[field][:label]}'", row_num)
  end

  def validate_state_field(field, value, row_num)
    return value if value.blank?
    return value if VALID_STATES.include?(value)

    normalized_state = STATE_ABBREVIATIONS[value.upcase]
    return normalized_state if normalized_state

    raise ValidationError.new("#{value} is not a valid state for field '#{VALIDATION[field][:label]}'", row_num)
  end
end

# Exception used for reporting validation errors
class ValidationError < StandardError
  def initialize(message, row_num)
    super("Validation Error: #{message} in row #{row_num}")
  end
end
