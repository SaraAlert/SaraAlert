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

  def epix
    redirect_to(root_url) && return unless current_user.can_import?

    # Load and parse Epi-X file
    begin
      xlxs = Roo::Excelx.new(params[:epix].tempfile.path, file_warning: :ignore)
      @patients = []
      xlxs.sheet(0).each_with_index do |row, index|
        next if index.zero? # Skip headers

        sex = 'Male' if row[13] == 'M'
        sex = 'Female' if row[13] == 'F'
        @patients << {
          user_defined_id_statelocal: row[0],
          flight_or_vessel_number: row[1],
          user_defined_id_cdc: row[4],
          primary_language: row[7],
          date_of_arrival: row[8],
          port_of_entry_into_usa: row[9],
          last_name: row[10],
          first_name: row[11],
          date_of_birth: row[12],
          sex: sex,
          address_line_1: row[16],
          address_city: row[17],
          address_state: row[18],
          address_zip: row[19],
          monitored_address_line_1: row[20],
          monitored_address_city: row[21],
          monitored_address_state: row[22],
          monitored_address_zip: row[23],
          primary_telephone: Phonelib.parse(row[28], 'US').full_e164,
          secondary_telephone: Phonelib.parse(row[29], 'US').full_e164,
          email: row[30],
          potential_exposure_location: row[35],
          potential_exposure_country: row[35],
          date_of_departure: row[36],
          contact_of_known_case: !row[41].blank?,
          was_in_health_care_facility_with_known_cases: !row[42].blank?,
          appears_to_be_duplicate: current_user.viewable_patients.matches(row[11], row[10], sex, row[12]).exists?,
          isolation: params.permit(:workflow)[:workflow] == 'isolation'
        }
      end
    rescue StandardError
      redirect_to(controller: 'import', action: 'error') && (return)
    end
  end

  def download_guidance
    send_file(
      "#{Rails.root}/public/sara_alert_comprehensive_monitoree.xlsx",
      filename: 'sara_alert_comprehensive_monitoree.xlsx',
      type: 'application/vnd.ms-excel'
    )
  end

  def comprehensive_monitorees # rubocop:todo Metrics/MethodLength
    redirect_to(root_url) && return unless current_user.can_import?

    @errors = []
    @patients = []
    # Load and parse patient import excel
    begin
      xlsx = Roo::Excelx.new(params[:comprehensive_monitorees].tempfile.path, file_warning: :ignore)
      validate_headers(:sara_alert_format, xlsx.sheet(0).row(1))
      xlsx.sheet(0).each_with_index do |row, index|
        next if index.zero? # Skip headers

        isolation = params.permit(:workflow)[:workflow] == 'isolation'

        patient = {
          first_name: validate_required_field(row[0], 'First Name', index),
          middle_name: row[1],
          last_name: validate_required_field(row[2], 'Last Name', index),
          date_of_birth: validate_required_field(row[3], 'Date of Birth', index),
          sex: validate_enum_field(row[4], 'Sex', index, %w[Male Female Unknown]),
          white: validate_bool_field(row[5], 'White', index),
          black_or_african_american: validate_bool_field(row[6], 'Black or African American', index),
          american_indian_or_alaska_native: validate_bool_field(row[7], 'American Indian or Alaska Native', index),
          asian: validate_bool_field(row[8], 'Asian', index),
          native_hawaiian_or_other_pacific_islander: validate_bool_field(row[9], 'Native Hawaiian or Other Pacific Islander', index),
          ethnicity: validate_enum_field(row[10], 'Ethnicity', index, ['Not Hispanic or Latino', 'Hispanic or Latino']),
          primary_language: row[11],
          secondary_language: row[12],
          interpretation_required: validate_bool_field(row[13], 'Interpretation Required?', index),
          nationality: row[14],
          user_defined_id_statelocal: row[15],
          user_defined_id_cdc: row[16],
          user_defined_id_nndss: row[17],
          address_line_1: validate_required_field(row[18], 'Address Line 1', index),
          address_city: validate_required_field(row[19], 'Address City', index),
          address_state: validate_and_normalize_state_field(validate_required_field(row[20], 'Address State', index), 'Address State', index),
          address_line_2: row[21],
          address_zip: validate_required_field(row[22], 'Address Zip', index),
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
          monitored_address_state: validate_and_normalize_state_field(row[33], 'Monitored Address State', index),
          monitored_address_line_2: row[34],
          monitored_address_zip: row[35],
          monitored_address_county: row[36],
          foreign_monitored_address_line_1: row[37],
          foreign_monitored_address_city: row[38],
          foreign_monitored_address_state: validate_and_normalize_state_field(row[39], 'Monitored Address State', index),
          foreign_monitored_address_line_2: row[40],
          foreign_monitored_address_zip: row[41],
          foreign_monitored_address_county: row[42],
          preferred_contact_method: validate_enum_field(validate_required_field(row[43], 'Preferred Contact Method', index), 'Preferred Contact Method', index, ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message']),
          primary_telephone: Phonelib.parse(row[44], 'US').full_e164,
          primary_telephone_type: validate_enum_field(row[45], 'Primary Telephone Type', index, ['Smartphone', 'Plain Cell', 'Landline']),
          secondary_telephone: Phonelib.parse(row[46], 'US').full_e164,
          secondary_telephone_type: validate_enum_field(row[47], 'Secondary Telephone Type', index, ['Smartphone', 'Plain Cell', 'Landline']),
          preferred_contact_time: validate_enum_field(row[48], 'Preferred Contact Time', index, %w[Morning Afternoon Evening]),
          email: row[49],
          port_of_origin: row[50],
          date_of_departure: row[51],
          source_of_report: row[52],
          flight_or_vessel_number: row[53],
          flight_or_vessel_carrier: row[54],
          port_of_entry_into_usa: row[55],
          date_of_arrival: row[56],
          travel_related_notes: row[57],
          additional_planned_travel_type: validate_enum_field(row[58], 'Additional Planned Travel Type', index, %w[Domestic International]),
          additional_planned_travel_destination: row[59],
          additional_planned_travel_destination_state: validate_and_normalize_state_field(row[60], 'Additional Planned Travel Destination State', index),
          additional_planned_travel_destination_country: row[61],
          additional_planned_travel_port_of_departure: row[62],
          additional_planned_travel_start_date: row[63],
          additional_planned_travel_end_date: row[64],
          additional_planned_travel_related_notes: row[65],
          last_date_of_exposure: validate_required_field(row[66], 'Last Date of Exposure', index),
          potential_exposure_location: row[67],
          potential_exposure_country: row[68],
          contact_of_known_case: validate_bool_field(row[69], 'Contact of Known Case?', index),
          contact_of_known_case_id: row[70],
          travel_to_affected_country_or_area: validate_bool_field(row[71], 'Travel to Affected Country or Area?', index),
          was_in_health_care_facility_with_known_cases: validate_bool_field(row[72], 'Was in Health Care Facility With Known Cases?', index),
          was_in_health_care_facility_with_known_cases_facility_name: row[73],
          laboratory_personnel: validate_bool_field(row[74], 'Laboratory Personnel?', index),
          laboratory_personnel_facility_name: row[75],
          healthcare_personnel: validate_bool_field(row[76], 'Healthcare Personnel?', index),
          healthcare_personnel_facility_name: row[77],
          crew_on_passenger_or_cargo_flight: validate_bool_field(row[78], 'Crew on Passenger or Cargo Flight?', index),
          member_of_a_common_exposure_cohort: validate_bool_field(row[79], 'Member of a Common Exposure Cohort?', index),
          member_of_a_common_exposure_cohort_type: row[80],
          exposure_risk_assessment: validate_enum_field(row[81], 'Exposure Risk Assessment', index, ['High', 'Medium', 'Low', 'No Identified Risk']),
          monitoring_plan: validate_enum_field(row[82], 'Monitoring Plan', index, ['None', 'Daily active monitoring', 'Self-monitoring with public health supervision', 'Self-monitoring with delegated supervision', 'Self-observation']),
          exposure_notes: row[83],
          symptom_onset: isolation ? row[85] : nil,
          case_status: isolation ? row[86] : nil,
          appears_to_be_duplicate: current_user.viewable_patients.matches(row[0], row[2], row[4], row[3]).exists?,
          isolation: isolation
        }

        lab_results = []
        lab_results.push(lab_result(row[87..90])) if !row[87].blank? || !row[88].blank? || !row[89].blank? || !row[90].blank?
        lab_results.push(lab_result(row[91..94])) if !row[91].blank? || !row[92].blank? || !row[93].blank? || !row[94].blank?
        patient[:laboratories] = lab_results unless lab_results.empty?

        @patients << patient
      rescue ValidationError => e
        @errors << e&.message || "Unknown error on row #{index}"
      rescue StandardError => e
        @errors << e&.message || 'Unexpected error'
      end
    rescue Zip::Error
      # Roo throws this if the file is not an excel file
      @errors << 'File Error: Please make sure that your import file is a .xlsx file.'
    rescue ArgumentError
      # Roo throws this error when the columns are not what we expect
      @errors << 'Format Error: Please make sure that .xlsx import file is formatted in accordance with the formatting guidance.'
    rescue StandardError => e
      # This is a catch all for any other unexpected error
      @errors << "Unexpected Error: '#{e&.message}' Please make sure that .xlsx import file is formatted in accordance with the formatting guidance."
    end
  end

  def lab_result(data)
    {
      lab_type: data[0],
      specimen_collection: data[1],
      report: data[2],
      result: data[3]
    }
  end

  private

  def validate_headers(format, row)
    if format == :sara_alert_format
      COMPREHENSIVE_HEADERS.each_with_index do |field, index|
        raise ValidationError.new("Incorrect header for field #{field}", 1) if field != row[index]
      end
    end
  end

  def validate_required_field(value, field, row_number)
    raise ValidationError.new("Required field '#{field}' is missing", row_number) if value.blank?

    value
  end

  def validate_enum_field(value, field, row_number, values)
    return value if value.blank? || values.include?(value)

    raise ValidationError.new("#{value} is not one of the accepted values for field '#{field}', acceptable values are: 'True' and 'False'", row_number)
  end

  def validate_bool_field(value, field, row_number)
    return value if value.blank?
    return (value.to_s.downcase == 'true') if %w[true false].include? value.to_s.downcase

    raise ValidationError.new("#{value} is not one of the accepted values for field '#{field}', acceptable values are: #{values.to_sentence}", row_number)
  end

  def validate_and_normalize_state_field(value, field, row_number)
    return value if value.blank?

    return value if VALID_STATES.include?(value)
    
    return STATE_ABBREVIATIONS[value] if STATE_ABBREVIATIONS[value]

    raise ValidationError.new("#{value} is not a valid state for field '#{field}'", row_number) if state.nil?
  end
end

# Exception used for reporting validation errors
class ValidationError < StandardError
  def initialize(message, row)
    super('Validation Error: ' + message + ' on row ' + row.to_s)
  end
end
