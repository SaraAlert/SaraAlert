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

    redirect_to(root_url) && return unless params.permit(:format)[:format] == 'epix' || params.permit(:format)[:format] == 'sara_alert_format'

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

        fields = format == :epix ? EPI_X_FIELDS : SARA_ALERT_FORMAT_FIELDS
        patient = { isolation: workflow == :isolation }
        fields.each_with_index do |field, col_num|
          next if field.nil?

          begin
            if format == :sara_alert_format
              if col_num == 95
                patient[:jurisdiction_id], patient[:jurisdiction_path] = validate_jurisdiction(row[95], row_ind, valid_jurisdiction_ids)
              elsif col_num == 96
                patient[:assigned_user] = import_assigned_user(row[96])
              elsif col_num == 85 && workflow == :isolation
                patient[:user_defined_symptom_onset] = row[85].present?
                patient[field] = import_field(field, row[col_num], row_ind)
              # TODO: when workflow specific case status validation re-enabled: uncomment
              # elsif col_num == 86
              #   patient[field] = validate_workflow_specific_enums(workflow, field, row[col_num], row_ind)
              else
                # TODO: when workflow specific case status validation re-enabled: this line can be updated to not have to check the 86 col
                patient[field] = import_field(field, row[col_num], row_ind) unless [85, 86].include?(col_num) && workflow != :isolation
              end
            end

            if format == :epix
              patient[field] = if col_num == 34 # copy over potential exposure country to location
                                 import_field(field, row[35], row_ind)
                               elsif [41, 42].include?(col_num) # contact of known case and was in healthcare facilities
                                 import_field(field, !row[col_num].blank?, row_ind)
                               else
                                 import_field(field, row[col_num], row_ind)
                               end
            end
          rescue ValidationError => e
            @errors << e&.message || "Unknown error on row #{row_ind}"
          rescue StandardError => e
            @errors << e&.message || 'Unexpected error'
          end
        end

        begin
          # Validate using Patient model validators without saving
          validation_patient = Patient.new(patient.slice(*Patient.attribute_names.map(&:to_sym)))
          unless validation_patient.valid?(:import)
            format_model_validation_errors(validation_patient).each do |error|
              @errors << ValidationError.new(error, row_ind).message
            end
          end

          if format == :sara_alert_format
            lab_results = []
            lab_results.push(lab_result(row[87..90], row_ind)) if !row[87].blank? || !row[88].blank? || !row[89].blank? || !row[90].blank?
            lab_results.push(lab_result(row[91..94], row_ind)) if !row[91].blank? || !row[92].blank? || !row[93].blank? || !row[94].blank?
            patient[:laboratories_attributes] = lab_results unless lab_results.empty?

            # Validate using Laboratory model validators without saving
            lab_results.each do |lab_data|
              validation_lab_result = Laboratory.new(lab_data)
              next if validation_lab_result.valid?(:import)

              format_model_validation_errors(validation_lab_result).each do |error|
                @errors << ValidationError.new(error, row_ind).message
              end
            end

          end

          # Checking for duplicates under current user's viewable patients is acceptable because custom jurisdictions must fall under hierarchy
          patient[:duplicate_data] = current_user.viewable_patients.duplicate_data_detection(patient)
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
      lab_type: import_field(:lab_type, data[0], row_ind),
      specimen_collection: import_field(:specimen_collection, data[1], row_ind),
      report: import_field(:report, data[2], row_ind),
      result: import_field(:result, data[3], row_ind)
    }
  end

  private

  def validate_headers(format, headers)
    case format
    when :sara_alert_format
      SARA_ALERT_FORMAT_HEADERS.each_with_index do |field, col_num|
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

  def import_field(field, value, row_ind)
    return value unless VALIDATION[field]

    # TODO: Un-comment when required fields are to be checked upon import
    # value = validate_required_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:required)
    value = import_enum_field(field, value) if VALIDATION[field][:checks].include?(:enum)
    value = import_and_validate_bool_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:bool)
    value = import_date_field(value) if VALIDATION[field][:checks].include?(:date)
    value = import_phone_field(value) if VALIDATION[field][:checks].include?(:phone)
    value = import_and_validate_state_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:state)
    value = import_sex_field(field, value) if VALIDATION[field][:checks].include?(:sex)
    value = import_email_field(value) if VALIDATION[field][:checks].include?(:email)
    value
  end

  def validate_required_field(field, value, row_ind)
    raise ValidationError.new("Required field '#{VALIDATION[field][:label]}' is missing", row_ind) if value.blank?

    value
  end

  def import_enum_field(field, value)
    return nil if value.blank?

    normalized_value = normalize_enum_field_value(value)
    NORMALIZED_ENUMS[field].keys.include?(normalized_value) ? NORMALIZED_ENUMS[field][normalized_value] : value
  end

  def import_and_validate_bool_field(field, value, row_ind)
    return value if value.blank?
    return (value.to_s.downcase == 'true') if %w[true false].include?(value.to_s.downcase)

    # NOTE: The controller still validates boolean values, since validating those on the model does not work
    # because by that point they will have been typecast from a string to a bool
    err_msg = "Value '#{value}' for '#{VALIDATION[field][:label]}' is not an acceptable value, acceptable values are: 'True' and 'False'"
    raise ValidationError.new(err_msg, row_ind)
  end

  def import_date_field(value)
    value.blank? ? nil : value
  end

  def import_phone_field(value)
    e_164 = Phonelib.parse(value, 'US').full_e164
    e_164.blank? ? value : e_164
  end

  def import_and_validate_state_field(field, value, row_ind)
    return nil if value.blank?
    return normalize_and_get_state_name(value) if VALID_STATES.include?(normalize_and_get_state_name(value))

    normalized_state = STATE_ABBREVIATIONS[value.upcase.to_sym]
    return normalized_state if normalized_state

    # NOTE: Currently only import allows abbreviated state names. If that changes and we begin allowing abbreviations
    # via other controllers, it will probably make sense to move this error onto the Patient model
    err_msg = "'#{value}' is not a valid state for '#{VALIDATION[field][:label]}', please use the full state name or two letter abbreviation"
    raise ValidationError.new(err_msg, row_ind)
  end

  def import_sex_field(field, value)
    return nil if value.blank?

    normalized_value = normalize_enum_field_value(value)
    return NORMALIZED_ENUMS[field][normalized_value] if NORMALIZED_ENUMS[field].keys.include?(normalized_value)

    normalized_sex = SEX_ABBREVIATIONS[value.upcase.to_sym]
    normalized_sex || value
  end

  def import_email_field(value)
    value.blank? ? nil : value
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

  def import_assigned_user(value)
    value.blank? ? nil : value
  end

  def validate_workflow_specific_enums(workflow, field, value, row_ind)
    return nil if value.blank?

    normalized_value = normalize_enum_field_value(value)
    if workflow == :exposure
      return NORMALIZED_EXPOSURE_ENUMS[field][normalized_value] if NORMALIZED_EXPOSURE_ENUMS[field].keys.include?(normalized_value)

      err_msg = "'#{value}' is not an acceptable value for '#{VALIDATION[field][:label]}' for monitorees imported into the Exposure workflow, "
      err_msg += "acceptable values are: #{VALID_EXPOSURE_ENUMS[field].to_sentence}"
    else
      return NORMALIZED_ISOLATION_ENUMS[field][normalized_value] if NORMALIZED_ISOLATION_ENUMS[field].keys.include?(normalized_value)

      err_msg = "'#{value}' is not an acceptable value for '#{VALIDATION[field][:label]}' for cases imported into the Isolation workflow, "
      err_msg += "acceptable values are: #{VALID_ISOLATION_ENUMS[field].to_sentence}"
    end
    raise ValidationError.new(err_msg, row_ind)
  end
end

# Exception used for reporting validation errors
class ValidationError < StandardError
  def initialize(message, row_ind)
    super("Validation Error (row #{row_ind + 1}): #{message}")
  end
end
