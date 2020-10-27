# frozen_string_literal: true

require 'roo'

# ImportController: for importing subjects from other formats
class ImportController < ApplicationController
  include ImportExport
  include PatientHelper

  before_action :authenticate_user!

  def index
    redirect_to(root_url) && return unless current_user.can_import?
  end

  def download_guidance
    send_file(
      "#{Rails.root}/public/Sara%20Alert%20Import%20Format.xlsx",
      filename: 'Sara%20Alert%20Import%20Format.xlsx',
      type: 'application/vnd.ms-excel'
    )
  end

  def import
    redirect_to(root_url) && return unless current_user.can_import?

    redirect_to(root_url) && return unless params.permit(:workflow)[:workflow] == 'exposure' || params.permit(:workflow)[:workflow] == 'isolation'

    redirect_to(root_url) && return unless params.permit(:format)[:format] == 'epix' || params.permit(:format)[:format] == 'comprehensive_monitorees'

    workflow = params.permit(:workflow)[:workflow].to_sym
    format = params.permit(:format)[:format].to_sym

    valid_jurisdiction_ids = current_user.jurisdiction.subtree.pluck(:id)

    @errors = []
    @patients = []

    # Load and parse patient import excel
    begin
      xlsx = Roo::Excelx.new(params[:file].tempfile.path, file_warning: :ignore)
      validate_headers(format, xlsx.sheet(0).row(1))
      raise ValidationError.new('File must contain at least one monitoree to import', 2) if xlsx.sheet(0).last_row < 2
      raise ValidationError.new('Please limit each import to 1000 monitorees.', 1000) if xlsx.sheet(0).last_row > 1000

      xlsx.sheet(0).each_with_index do |row, row_ind|
        next if row_ind.zero? # Skip headers

        fields = format == :epix ? EPI_X_FIELDS : COMPREHENSIVE_FIELDS
        patient = { isolation: workflow == :isolation }
        fields.each_with_index do |field, col_num|
          next if field.nil?

          begin
            if format == :comprehensive_monitorees
              if col_num == 95
                patient[:jurisdiction_id], patient[:jurisdiction_path] = validate_jurisdiction(row[95], row_ind, valid_jurisdiction_ids)
              elsif col_num == 96
                patient[:assigned_user] = validate_assigned_user(row[96], row_ind)
              elsif col_num == 85 && workflow == :isolation
                patient[:user_defined_symptom_onset] = row[85].present?
                patient[field] = validate_field(field, row[col_num], row_ind)
              else
                patient[field] = validate_field(field, row[col_num], row_ind) unless [85, 86].include?(col_num) && workflow != :isolation
              end
            end

            if format == :epix
              patient[field] = if col_num == 34 # copy over potential exposure country to location
                                 validate_field(field, row[35], row_ind)
                               elsif [41, 42].include?(col_num) # contact of known case and was in healthcare facilities
                                 validate_field(field, !row[col_num].blank?, row_ind)
                               else
                                 validate_field(field, row[col_num], row_ind)
                               end
            end
          rescue ValidationError => e
            @errors << e&.message || "Unknown error on row #{row_ind}"
          rescue StandardError => e
            @errors << e&.message || 'Unexpected error'
          end
        end

        begin
          # Run validations on fields that have restrictions conditional on other fields
          validate_required_primary_contact(patient, row_ind)

          # Checking for duplicates under current user's viewable patients is acceptable because custom jurisdictions must fall under hierarchy
          patient[:duplicate_data] = current_user.viewable_patients.duplicate_data(patient[:first_name],
                                                                                   patient[:last_name],
                                                                                   patient[:sex],
                                                                                   patient[:date_of_birth],
                                                                                   patient[:user_defined_id_statelocal])

          if format == :comprehensive_monitorees
            lab_results = []
            lab_results.push(lab_result(row[87..90], row_ind)) if !row[87].blank? || !row[88].blank? || !row[89].blank? || !row[90].blank?
            lab_results.push(lab_result(row[91..94], row_ind)) if !row[91].blank? || !row[92].blank? || !row[93].blank? || !row[94].blank?
            patient[:laboratories] = lab_results unless lab_results.empty?
          end
        rescue ValidationError => e
          @errors << e&.message || "Unknown error on row #{row_ind}"
        rescue StandardError => e
          @errors << e&.message || 'Unexpected error'
        end
        @patients << patient
      end
    rescue ValidationError => e
      @errors << e&.message || "Unknown error on row #{row_ind}"
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

    render json: { patients: @patients, errors: @errors }
  end

  def lab_result(data, row_ind)
    {
      lab_type: data[0],
      specimen_collection: validate_field(:specimen_collection, data[1], row_ind),
      report: validate_field(:report, data[2], row_ind),
      result: data[3]
    }
  end

  private

  def validate_headers(format, headers)
    case format
    when :comprehensive_monitorees
      COMPREHENSIVE_HEADERS.each_with_index do |field, col_num|
        next if field == headers[col_num]

        err_msg = "Invalid header in column #{col_num} should be '#{field}' instead of '#{headers[col_num]}'. "\
                  'Please make sure to use the latest format specified by the Sara Alert Format guidance doc.'
        raise ValidationError.new(err_msg, 1)
      end
    when :epix
      EPI_X_HEADERS.each_with_index do |field, col_num|
        next if field == headers[col_num]

        err_msg = "Invalid header in column #{col_num} should be '#{field}' instead of '#{headers[col_num]}'. "\
                  'Please make sure to use the latest Epi-X format.'
        raise ValidationError.new(err_msg, 1)
      end
    end
  end

  def validate_field(field, value, row_ind)
    return value unless VALIDATION[field]

    # TODO: Un-comment when required fields are to be checked upon import
    # value = validate_required_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:required)
    value = validate_enum_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:enum)
    value = validate_bool_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:bool)
    value = validate_date_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:date)
    value = validate_phone_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:phone)
    value = validate_state_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:state)
    value = validate_sex_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:sex)
    value = validate_email_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:email)
    value
  end

  def validate_required_field(field, value, row_ind)
    raise ValidationError.new("Required field '#{VALIDATION[field][:label]}' is missing", row_ind) if value.blank?

    value
  end

  def validate_enum_field(field, value, row_ind)
    return nil if value.blank?

    normalized_value = unformat_enum_field(value)
    return NORMALIZED_ENUMS[field][normalized_value] if NORMALIZED_ENUMS[field].keys.include?(normalized_value)

    err_msg = "'#{value}' is not an acceptable value for '#{VALIDATION[field][:label]}', acceptable values are: #{VALID_ENUMS[field].to_sentence}"
    raise ValidationError.new(err_msg, row_ind)
  end

  def validate_bool_field(field, value, row_ind)
    return value if value.blank?
    return (value.to_s.downcase == 'true') if %w[true false].include?(value.to_s.downcase)

    err_msg = "'#{value}' is not an acceptable value for '#{VALIDATION[field][:label]}', acceptable values are: 'True' and 'False'"
    raise ValidationError.new(err_msg, row_ind)
  end

  def validate_date_field(field, value, row_ind)
    return nil if value.blank?
    return value if value.instance_of?(Date)

    unless value.match(/\d{4}-\d{2}-\d{2}/)
      err_msg = "'#{value}' is not a valid date for '#{VALIDATION[field][:label]}'"
      if value.match(%r{\d{2}/\d{2}/\d{4}})
        raise ValidationError.new("#{err_msg} due to ambiguity between 'MM/DD/YYYY' and 'DD/MM/YYYY', please use the 'YYYY-MM-DD' format instead", row_ind)
      end

      raise ValidationError.new("#{err_msg}, please use the 'YYYY-MM-DD' format", row_ind)
    end

    begin
      Date.parse(value)
    rescue ArgumentError
      raise ValidationError.new("'#{value}' is not a valid date for '#{VALIDATION[field][:label]}'", row_ind)
    end
  end

  def validate_phone_field(field, value, row_ind)
    return nil if value.blank?

    phone = Phonelib.parse(value, 'US')
    return phone.full_e164 unless phone.national(false).nil? || phone.national(false).length != 10

    raise ValidationError.new("'#{value}' is not a valid phone number for '#{VALIDATION[field][:label]}'", row_ind)
  end

  def validate_state_field(field, value, row_ind)
    return nil if value.blank?
    return normalize_and_get_state_name(value) if VALID_STATES.include?(normalize_and_get_state_name(value))

    normalized_state = STATE_ABBREVIATIONS[value.upcase.to_sym]
    return normalized_state if normalized_state

    err_msg = "'#{value}' is not a valid state for '#{VALIDATION[field][:label]}', please use the full state name or two letter abbreviation"
    raise ValidationError.new(err_msg, row_ind)
  end

  def validate_sex_field(field, value, row_ind)
    return nil if value.blank?
    return value if %w[Male Female Unknown].include?(value.capitalize)

    normalized_sex = SEX_ABBREVIATIONS[value.upcase.to_sym]
    return normalized_sex if normalized_sex

    raise ValidationError.new("'#{value}' is not a valid sex for '#{VALIDATION[field][:label]}'", row_ind)
  end

  def validate_email_field(field, value, row_ind)
    return nil if value.blank?
    unless ValidEmail2::Address.new(value).valid?
      raise ValidationError.new("'#{value}' is not a valid Email Address for '#{VALIDATION[field][:label]}'", row_ind)
    end

    value
  end

  def validate_jurisdiction(value, row_ind, valid_jurisdiction_ids)
    return nil if value.blank?

    jurisdiction = Jurisdiction.where(path: value).first
    if jurisdiction.nil?
      raise ValidationError.new("'#{value}' is not valid for 'Full Assigned Jurisdiction Path'", row_ind) if Jurisdiction.where(name: value).empty?

      raise ValidationError.new("'#{value}' is not valid for 'Full Assigned Jurisdiction Path', please provide the full path instead of just the name", row_ind)
    end

    return jurisdiction[:id], jurisdiction[:path] if valid_jurisdiction_ids.include?(jurisdiction[:id])

    raise ValidationError.new("'#{value}' is not valid for 'Full Assigned Jurisdiction Path' because you do not have permission to import into it", row_ind)
  end

  def validate_assigned_user(value, row_ind)
    return nil if value.blank?

    return value.to_i if value.to_i.between?(1, 9999)

    raise ValidationError.new("'#{value}' is not valid for 'Assigned User', acceptable values are numbers between 1-9999", row_ind)
  end

  def validate_required_primary_contact(patient, row_ind)
    if patient[:email].blank? && patient[:preferred_contact_method] == 'E-mailed Web Link'
      raise ValidationError.new("'Email' is required when Primary Contact Method is 'E-mailed Web Link'", row_ind)
    end
    unless patient[:primary_telephone].blank? && (['SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].include? patient[:preferred_contact_method])
      return
    end

    raise ValidationError.new("'Primary Telephone' is required when Primary Contact Method is '#{patient[:preferred_contact_method]}'", row_ind)
  end
end

# Exception used for reporting validation errors
class ValidationError < StandardError
  def initialize(message, row_ind)
    super("Validation Error (row #{row_ind + 1}): #{message}")
  end
end
