# frozen_string_literal: true

# ExportController: for exporting subjects
class ExportController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def csv_linelist
    # Verify params
    redirect_to(root_url) && return unless %w[exposure isolation].include?(params[:workflow])

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
      filename: "Sara-Alert-Linelist-#{params[:workflow] == 'isolation' ? 'Isolation' : 'Exposure'}",
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
    redirect_to(root_url) && return unless %w[exposure isolation].include?(params[:workflow])

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
      filename: "Sara-Alert-Format-##{params[:workflow] == 'isolation' ? 'Isolation' : 'Exposure'}",
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
      separate_files: true,
      data: {
        patients: {
          checked: FULL_HISTORY_PATIENTS_FIELDS,
          headers: FULL_HISTORY_PATIENTS_HEADERS,
          query: params[:scope] == 'purgeable' ? { purgeable: true } : {},
          name: 'Monitorees',
          tab: 'Monitorees List'
        },
        # assessment fields and headers need to be duplicated because they may be modified
        assessments: {
          checked: FULL_HISTORY_ASSESSMENTS_FIELDS.dup,
          headers: FULL_HISTORY_ASSESSMENTS_HEADERS.dup,
          name: 'Reports',
          tab: 'Reports'
        },
        laboratories: {
          checked: FULL_HISTORY_LABORATORIES_FIELDS,
          headers: FULL_HISTORY_LABORATORIES_HEADERS,
          name: 'Lab-Results',
          tab: 'Lab Results'
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

    config = {
      format: 'xlsx',
      separate_files: false,
      data: {
        patients: {
          checked: FULL_HISTORY_PATIENTS_FIELDS,
          headers: FULL_HISTORY_PATIENTS_HEADERS,
          tab: 'Monitorees List'
        },
        # assessment fields and headers need to be duplicated because they may be modified
        assessments: {
          checked: FULL_HISTORY_ASSESSMENTS_FIELDS.dup,
          headers: FULL_HISTORY_ASSESSMENTS_HEADERS.dup,
          tab: 'Reports'
        },
        laboratories: {
          checked: FULL_HISTORY_LABORATORIES_FIELDS,
          headers: FULL_HISTORY_LABORATORIES_HEADERS,
          tab: 'Lab Results'
        },
        histories: {
          checked: FULL_HISTORY_HISTORIES_FIELDS,
          headers: FULL_HISTORY_HISTORIES_HEADERS,
          tab: 'Edit Histories'
        }
      }
    }

    data_types = CUSTOM_EXPORT_OPTIONS.keys.select { |data_type| config.dig(:data, data_type, :checked).present? }
    field_data = get_field_data(config)

    workbook = FastExcel.open
    sheets = {}
    last_row_nums = {}
    data_types.each do |data_type|
      worksheet = workbook.add_worksheet(config.dig(:data, data_type, :tab) || CUSTOM_EXPORT_OPTIONS.dig(data_type, :label))
      worksheet.auto_width = true
      worksheet.append_row(field_data.dig(data_type, :headers))
      last_row_nums[data_type] = 0
      sheets[data_type] = worksheet
    end

    exported_data = get_export_data(patients, config[:data])
    data_types.each do |data_type|
      last_row_nums[data_type] = write_xlsx_rows(exported_data, data_type, sheets[data_type], field_data[data_type][:checked], last_row_nums[data_type])
    end

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
    exp_recently = current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.hour.ago).exists?
    render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401 if exp_recently
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
