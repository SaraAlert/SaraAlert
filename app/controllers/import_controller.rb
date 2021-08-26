# frozen_string_literal: true

require 'roo'

# ImportController: for importing subjects from other formats
class ImportController < ApplicationController
  include ExportHelper
  include PatientHelper

  before_action :authenticate_user!

  FOREIGN_ADDRESS_MAPPINGS = {
    address_line_1: :foreign_address_line_1,
    address_city: :foreign_address_city,
    address_state: :foreign_address_state,
    address_zip: :foreign_address_zip,
    address_line_2: :foreign_address_line_2
  }.freeze

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
      if format == :epix
        ext = File.extname(params[:file].tempfile.path)
        raise FileFormatError.new('File format must be .csv', ext) unless ext == '.csv'

        csv = CSV.read(params[:file].tempfile.path, headers: true, skip_blanks: true, skip_lines: /^(?:,\s*)+$/)
        validate_headers(format, csv.headers)
      else
        xlsx = Roo::Excelx.new(params[:file].tempfile.path, file_warning: :ignore)
        validate_headers(format, xlsx.sheet(0).row(1))
      end

      num_rows = format == :epix ? csv.length : xlsx.sheet(0).last_row - 1
      raise ValidationError.new('File must contain at least one monitoree to import', 2) if num_rows < 1
      raise ValidationError.new('Please limit each import to 1000 monitorees.', 1000) if num_rows > 1000

      # Define patients for duplicate detection here to avoid duplicate queries
      patients_for_duplicate_detection = current_user.viewable_patients

      records = format == :epix ? csv : xlsx.sheet(0)
      records.each_with_index do |row, row_ind|
        next if row_ind.zero? && format == :sara_alert_format # Skip headers for excel file

        fields = format == :epix ? EPI_X_FIELDS : SARA_ALERT_FORMAT_FIELDS
        patient = { isolation: workflow == :isolation }

        # Determine whether perm address is domestic or international for epix format
        international_address = format == :epix && row[EPI_X_FIELDS.index(:foreign_address_country)].present? &&
                                row[EPI_X_FIELDS.index(:foreign_address_country)]&.downcase&.strip != 'united states'

        # Import patient fields
        fields.each_with_index do |field, col_num|
          # Skip fields that are not imported
          next if field.nil?

          begin
            import_sara_alert_format_field(patient, field, row, row_ind, col_num, workflow, valid_jurisdiction_ids) if format == :sara_alert_format
            import_epi_x_field(patient, field, row, row_ind, col_num, international_address) if format == :epix
          rescue Date::Error
            @errors << "Validation Error (row #{row_ind + 1}): '#{row[col_num]}' is not a valid date for '#{EPI_X_HEADERS[EPI_X_FIELDS.index(field)]}'"
          rescue StandardError => e
            @errors << e&.message || "Unexpected error on row #{row_ind + 1} for #{field}: #{row[col_num]}"
          end
        end

        # Import lab results and vaccinations if present
        if format == :sara_alert_format
          lab_results = []
          lab_results.push(lab_result(row[87..90], row_ind)) if row[87..90].filter(&:present?).any?
          lab_results.push(lab_result(row[91..94], row_ind)) if row[91..94].filter(&:present?).any?
          patient[:laboratories_attributes] = lab_results unless lab_results.empty?

          # Validate using Laboratory model validators without saving
          lab_results.each do |lab_data|
            validation_lab_result = Laboratory.new(lab_data)
            next if validation_lab_result.valid?(:import)

            format_model_validation_errors(validation_lab_result).each do |error|
              @errors << ValidationError.new(error, row_ind).message
            end
          end

          vaccines = []
          vaccines.push(vaccination(row[102..106], row_ind)) if row[102..106].filter(&:present?).any?
          vaccines.push(vaccination(row[107..111], row_ind)) if row[107..111].filter(&:present?).any?
          vaccines.push(vaccination(row[114..118], row_ind)) if row[114..118].filter(&:present?).any?

          patient[:vaccines_attributes] = vaccines unless vaccines.empty?

          # Validate using Vaccine model validators without saving
          vaccines.each do |vaccine_data|
            validation_vaccine = Vaccine.new(vaccine_data)
            next if validation_vaccine.valid?

            format_model_validation_errors(validation_vaccine).each do |error|
              @errors << ValidationError.new(error, row_ind).message
            end
          end
        end

        # Validate using Patient model validators without saving
        validation_patient = Patient.new(patient.slice(*Patient.attribute_names.map(&:to_sym)))
        unless validation_patient.valid?(:import)
          format_model_validation_errors(validation_patient).each do |error|
            @errors << ValidationError.new(error, row_ind).message
          end
        end

        # Checking for duplicates under current user's viewable patients is acceptable because custom jurisdictions must fall under hierarchy
        patient[:duplicate_data] = patients_for_duplicate_detection.duplicate_data_detection(patient)

        @patients << patient
      end
    rescue ValidationError => e
      @errors << e&.message || "Unknown error on row #{row_ind + 1}"
    rescue Zip::Error, FileFormatError
      # Roo throws this if the file is not an excel file
      @errors << "File Error: Please make sure that your import file is a .#{format == :epix ? 'csv' : 'xlsx'} file."
    rescue ArgumentError, NoMethodError
      # Roo throws this error when the columns are not what we expect
      @errors << "Format Error: Please make sure that .#{format == :epix ? 'csv' : 'xlsx'} import file is formatted in accordance with the formatting guidance."
    rescue StandardError => e
      # This is a catch all for any other unexpected error
      @errors << "Unexpected Error: '#{e&.message}' Please make sure that .#{format == :epix ? 'csv' : 'xlsx'} import file is formatted in accordance with the"\
                 ' formatting guidance.'
    end

    render json: { patients: @patients, errors: @errors }
  end

  private

  def import_sara_alert_format_field(patient, field, row, row_ind, col_num, workflow, valid_jurisdiction_ids)
    if field == :jurisdiction_path
      patient[:jurisdiction_id], patient[:jurisdiction_path] = validate_jurisdiction(row[SARA_ALERT_FORMAT_FIELDS.index(:jurisdiction_path)],
                                                                                     row_ind, valid_jurisdiction_ids)
    elsif field == :assigned_user
      patient[:assigned_user] = import_assigned_user(row[SARA_ALERT_FORMAT_FIELDS.index(:assigned_user)])
    elsif field == :symptom_onset && workflow == :isolation
      patient[:user_defined_symptom_onset] = row[SARA_ALERT_FORMAT_FIELDS.index(:symptom_onset)].present?
      patient[field] = import_field(field, row[col_num], row_ind)
    # TODO: when workflow specific case status validation re-enabled: uncomment
    # elsif field == :case_status
    #   patient[field] = validate_workflow_specific_enums(workflow, field, row[col_num], row_ind)
    else
      # TODO: when workflow specific case status validation re-enabled: this line can be updated to not have to check the case_status field
      patient[field] = import_field(field, row[col_num], row_ind) unless %i[symptom_onset case_status].include?(field) && workflow != :isolation
    end
  end

  def import_epi_x_field(patient, field, row, row_ind, col_num, international_address)
    return if field == :foreign_address_country && !international_address

    if %i[travel_related_notes port_of_entry_into_usa].include?(field) # fields represented by multiple columns
      if patient[field].blank?
        patient[field] = "#{EPI_X_HEADERS[col_num]}: #{import_field(field, row[col_num], row_ind)}"
      else
        patient[field] += ", #{EPI_X_HEADERS[col_num]}: #{import_field(field, row[col_num], row_ind)}"
      end
    elsif field == :secondary_telephone && row[EPI_X_FIELDS.index(:primary_telephone)].blank? # populate primary telephone before secondary
      patient[:primary_telephone] = import_field(field, row[col_num], row_ind)
    elsif international_address && %i[address_line_1 address_city address_state address_zip address_line_2].include?(field)
      patient[FOREIGN_ADDRESS_MAPPINGS[field]] = import_field(field, row[col_num], row_ind)
    elsif %i[date_of_birth date_of_departure symptom_onset].include?(field)
      patient[field] = import_field(field, Date.strptime(row[col_num], '%m/%d/%Y'), row_ind) if row[col_num].present?
    elsif field == :date_of_arrival
      patient[field] = import_field(field, Date.strptime(row[col_num], '%b %d %Y'), row_ind) if row[col_num].present?
    else
      patient[field] = import_field(field, row[col_num], row_ind)
    end
  end

  def lab_result(data, row_ind)
    {
      lab_type: import_field(:lab_type, data[0], row_ind),
      specimen_collection: import_field(:specimen_collection, data[1], row_ind),
      report: import_field(:report, data[2], row_ind),
      result: import_field(:result, data[3], row_ind)
    }
  end

  def vaccination(data, row_ind)
    {
      group_name: import_field(:group_name, data[0], row_ind),
      product_name: import_field(:product_name, data[1], row_ind),
      administration_date: import_field(:administration_date, data[2], row_ind),
      dose_number: import_field(:dose_number, data[3], row_ind),
      notes: import_field(:notes, data[4], row_ind)
    }
  end

  def validate_headers(format, headers)
    case format
    when :sara_alert_format
      SARA_ALERT_FORMAT_HEADERS.each_with_index do |field, col_num|
        next if field == headers[col_num]

        err_msg = "Invalid header in column #{col_num} should be '#{field}' instead of '#{headers[col_num]}'. "\
                  'Please make sure to use the latest format specified by the Sara Alert Format guidance doc.'
        raise ValidationError.new(err_msg, 0)
      end
    when :epix
      EPI_X_HEADERS.each_with_index do |field, col_num|
        next if field == headers[col_num]

        err_msg = "Invalid header in column #{col_num} should be '#{field}' instead of '#{headers[col_num]}'. "\
                  'Please make sure to use the latest Epi-X format.'
        raise ValidationError.new(err_msg, 0)
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
    value = import_and_validate_time_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:time)
    value = import_phone_field(value) if VALIDATION[field][:checks].include?(:phone)
    value = import_and_validate_state_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:state)
    value = import_and_validate_language_field(field, value, row_ind) if VALIDATION[field][:checks].include?(:lang)
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

  def import_and_validate_time_field(field, value, row_ind)
    return nil if value.blank?

    normalized_value = value.to_s.downcase.strip
    saved_value = NORMALIZED_INVERTED_TIME_OPTIONS[normalized_value]
    return saved_value unless saved_value.blank?

    err_msg = "Value '#{value}' for '#{VALIDATION[field][:label]}' is not an acceptable value, acceptable values are: '#{TIME_OPTIONS.values.join("', '")}'"
    raise ValidationError.new(err_msg, row_ind)
  end

  def import_phone_field(value)
    e_164 = Phonelib.parse(value, 'US').full_e164
    e_164.blank? ? value : e_164
  end

  def import_and_validate_state_field(field, value, row_ind)
    return nil if value.blank?
    return normalize_and_get_state_name(value) if VALID_STATES.include?(normalize_and_get_state_name(value))

    normalized_state = STATE_ABBREVIATIONS[value.to_s.upcase.to_sym]
    return normalized_state if normalized_state

    # NOTE: Currently only import allows abbreviated state names. If that changes and we begin allowing abbreviations
    # via other controllers, it will probably make sense to move this error onto the Patient model
    err_msg = "'#{value}' is not a valid state for '#{VALIDATION[field][:label]}', please use the full state name or two letter abbreviation"
    raise ValidationError.new(err_msg, row_ind)
  end

  def import_and_validate_language_field(field, value, row_ind)
    return nil if value.blank?

    val = Languages.normalize_and_get_language_code(value)
    return val if val # val will the three-letter language code if value is matchable, else nil

    err_msg = "'#{value}' is not a valid language for '#{VALIDATION[field][:label]}'. Please use the full language name or three letter ISO-639 abbreviation"
    raise ValidationError.new(err_msg, row_ind)
  end

  def import_sex_field(field, value)
    return nil if value.blank?

    normalized_value = normalize_enum_field_value(value)
    return NORMALIZED_ENUMS[field][normalized_value] if NORMALIZED_ENUMS[field].keys.include?(normalized_value)

    normalized_sex = SEX_ABBREVIATIONS[value.to_s.upcase.to_sym]
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
      err_msg += "acceptable values are: #{VALID_EXPOSURE_ENUMS[field].reject(&:blank?).to_sentence}"
    else
      return NORMALIZED_ISOLATION_ENUMS[field][normalized_value] if NORMALIZED_ISOLATION_ENUMS[field].keys.include?(normalized_value)

      err_msg = "'#{value}' is not an acceptable value for '#{VALIDATION[field][:label]}' for cases imported into the Isolation workflow, "
      err_msg += "acceptable values are: #{VALID_ISOLATION_ENUMS[field].reject(&:blank?).to_sentence}"
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

# Exception used for reporting file format errors
class FileFormatError < StandardError
  def initialize(message, ext)
    super("File Format Error: #{message} but file format is #{ext}")
  end
end
