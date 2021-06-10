# frozen_string_literal: true

# ExportController: for exporting subjects
class ExportController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def csv_linelist
    # Verify params
    redirect_to(root_url) && return unless %w[global exposure isolation].include?(params[:workflow])

    export_type = "csv_linelist_#{params[:workflow]}".to_sym
    return if exported_recently?(export_type)

    # Clear out old receipts and create a new one
    current_user.export_receipts.where(export_type: export_type).destroy_all
    ExportReceipt.create(user_id: current_user.id, export_type: export_type)

    # Spawn job to handle export
    config = {
      user_id: current_user.id,
      export_type: export_type,
      format: 'csv',
      filename: "Sara-Alert-Linelist-#{params[:workflow].capitalize}",
      filename_data_type: false,
      data: {
        patients: {
          checked: LINELIST_FIELDS,
          headers: LINELIST_HEADERS,
          query: { workflow: params[:workflow] }
        }
      }
    }

    ExportJob.perform_later(config)

    respond_to do |format|
      format.any { head :ok }
    end
  end

  def sara_alert_format
    # Verify params
    redirect_to(root_url) && return unless %w[global exposure isolation].include?(params[:workflow])

    export_type = "sara_alert_format_#{params[:workflow]}".to_sym
    return if exported_recently?(export_type)

    # Clear out old receipts and create a new one
    current_user.export_receipts.where(export_type: export_type).destroy_all
    ExportReceipt.create(user_id: current_user.id, export_type: export_type)

    # Spawn job to handle export
    config = {
      user_id: current_user.id,
      export_type: export_type,
      format: 'xlsx',
      filename: "Sara-Alert-Format-##{params[:workflow].capitalize}",
      filename_data_type: false,
      data: {
        patients: {
          checked: SARA_ALERT_FORMAT_FIELDS,
          headers: SARA_ALERT_FORMAT_HEADERS,
          query: { workflow: params[:workflow] }
        }
      }
    }

    ExportJob.perform_later(config)

    respond_to do |format|
      format.any { head :ok }
    end
  end

  def full_history_patients
    # Verify params
    redirect_to(root_url) && return unless %w[purgeable all].include?(params[:scope])

    export_type = "full_history_patients_#{params[:scope]}".to_sym
    return if exported_recently?(export_type)

    # Clear out old receipts and create a new one
    current_user.export_receipts.where(export_type: export_type).destroy_all
    ExportReceipt.create(user_id: current_user.id, export_type: export_type)

    # Spawn job to handle export
    config = {
      user_id: current_user.id,
      export_type: export_type,
      format: 'xlsx',
      filename: "Sara-Alert-#{params[:scope] == 'purgeable' ? 'Purge-Eligible' : 'Full'}-Export",
      filename_data_type: true,
      data: {
        patients: {
          checked: FULL_HISTORY_PATIENTS_FIELDS,
          headers: FULL_HISTORY_PATIENTS_HEADERS,
          query: params[:scope] == 'purgeable' ? { purgeable: true } : {},
          name: 'Monitorees',
          tab: 'Monitorees List'
        },
        assessments: {
          checked: FULL_HISTORY_ASSESSMENTS_FIELDS,
          headers: FULL_HISTORY_ASSESSMENTS_HEADERS,
          name: 'Reports',
          tab: 'Reports'
        },
        laboratories: {
          checked: FULL_HISTORY_LABORATORIES_FIELDS,
          headers: FULL_HISTORY_LABORATORIES_HEADERS,
          name: 'Lab-Results',
          tab: 'Lab Results'
        },
        vaccines: {
          checked: FULL_HISTORY_VACCINES_FIELDS,
          headers: FULL_HISTORY_VACCINES_HEADERS,
          name: 'Vaccinations',
          tab: 'Vaccinations'
        },
        histories: {
          checked: FULL_HISTORY_HISTORIES_FIELDS,
          headers: FULL_HISTORY_HISTORIES_HEADERS,
          name: 'Histories',
          tab: 'Edit Histories'
        }
      }
    }

    ExportJob.perform_later(config)

    respond_to do |format|
      format.any { head :ok }
    end
  end

  def full_history_patient
    return unless current_user.viewable_patients.exists?(params[:patient_id])

    patients = current_user.viewable_patients.where(id: params[:patient_id])
    return if patients.empty?

    History.monitoree_data_downloaded(patient: patients.first, created_by: current_user.email)

    # NOTE: separate implementation used for single patient export for performance and to keep this endpoint's logic separate from main export logic
    # Get all of the field data based on the config
    field_data = get_field_data(FULL_HISTORY_PATIENT_CONFIG, patients)

    # Create export file
    workbook = FastExcel.open
    sheets = {}
    last_row_nums = {}
    FULL_HISTORY_PATIENT_CONFIG[:data].each_key do |data_type|
      # Add separate worksheet for each data type
      worksheet = workbook.add_worksheet(FULL_HISTORY_PATIENT_CONFIG[:data][data_type][:tab])
      worksheet.auto_width = true
      worksheet.append_row(field_data.dig(data_type, :headers))
      last_row_nums[data_type] = 0
      sheets[data_type] = worksheet
    end

    # Get export data hashes for each data type from config and write data to each sheet
    exported_data = get_export_data(patients, FULL_HISTORY_PATIENT_CONFIG[:data], field_data)
    FULL_HISTORY_PATIENT_CONFIG[:data].each_key do |data_type|
      exported_data[data_type]&.each do |record|
        # fast_excel unfortunately does not provide a method to modify the @last_row_number class variable so it needs to be manually kept track of
        last_row_nums[data_type] += 1
        record.each_with_index do |value, col_index|
          sheets[data_type].write_string(last_row_nums[data_type], col_index, value.to_s, nil)
        end
      end
    end

    # Send file
    send_data Base64.encode64(workbook.read_string)
  end

  # Single patient NBS export
  def nbs_patient
    redirect_to(root_url) && return unless current_user.can_export?
    return unless current_user.viewable_patients.exists?(params[:patient_id])

    patients = current_user.viewable_patients.where(id: params[:patient_id])
    return if patients.empty?

    send_data Base64.encode64(PHDC::Serializer.new.patients_to_phdc_zip(patients, patients.first.jurisdiction).string)
  end

  def custom_export
    export_type = :custom
    return if exported_recently?(export_type)

    unsanitized_config = params.require(:config).permit(:format, data: {})
    config = {
      user_id: current_user.id,
      export_type: export_type
    }

    # Validate format param
    config[:format] = unsanitized_config.require(:format)
    config[:filename_data_type] = config[:format] == 'csv'
    return head :bad_request unless EXPORT_FORMATS.include?(config[:format])

    # Validate data
    data = unsanitized_config.require(:data)
    begin
      config[:data] = {
        patients: {
          checked: validate_checked_fields(data, :patients),
          query: validate_patients_query(data.require(:patients)[:query])
        },
        assessments: {
          checked: validate_checked_fields(data, :assessments)
        },
        laboratories: {
          checked: validate_checked_fields(data, :laboratories)
        },
        vaccines: {
          checked: validate_checked_fields(data, :vaccines)
        },
        close_contacts: {
          checked: validate_checked_fields(data, :close_contacts)
        },
        transfers: {
          checked: validate_checked_fields(data, :transfers)
        },
        histories: {
          checked: validate_checked_fields(data, :histories)
        }
      }
    rescue StandardError => e
      return render json: e, status: :bad_request
    end

    # Clear out old receipts and create a new one
    current_user.export_receipts.where(export_type: export_type).destroy_all
    ExportReceipt.create(user_id: current_user.id, export_type: export_type)

    # Spawn job to handle export
    ExportJob.perform_later(config)

    respond_to do |f|
      f.any { head :ok }
    end
  end

  private

  def exported_recently?(export_type)
    exp_recently = current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 15.minutes.ago).exists?
    if exp_recently
      render json: { message: 'You have already initiated an export of this type in the last 15 minutes. Please try again later.' }.to_json,
             status: 401
    end
    exp_recently
  end

  def validate_checked_fields(data, data_type)
    unsanitized_checked = data.require(data_type).permit(checked: [])[:checked]
    raise StandardError('Checked must be an array') unless unsanitized_checked.is_a?(Array)

    checked = unsanitized_checked.map(&:to_sym)
    checked.each do |field|
      raise StandardError("Unknown field '#{field}' for '#{data_type}'") unless ALL_FIELDS_NAMES[data_type].keys.include?(field)
    end

    checked
  end

  def authenticate_user_role
    redirect_to(root_url) && return unless current_user.can_export?
  end
end
