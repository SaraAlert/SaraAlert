# frozen_string_literal: true

require 'axlsx'

# ExportController: for exporting subjects
class ExportController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def csv
    # Verify params
    redirect_to(root_url) && return unless %w[exposure isolation].include?(params[:workflow])

    export_type = "csv_#{params[:workflow]}".to_sym
    return if exported_recently?(export_type)

    # Clear out old receipts and create a new one
    current_user.export_receipts.where(export_type: export_type).destroy_all
    ExportReceipt.create(user_id: current_user.id, export_type: export_type)

    # Spawn job to handle export
    config = {
      user_id: current_user.id,
      export_type: export_type,
      format: 'csv',
      filename: "Sara-Alert-Linelist-#{params[:workflow]&.titleize}",
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

  def excel_sara_alert_format
    # Verify params
    redirect_to(root_url) && return unless %w[exposure isolation].include?(params[:workflow])

    export_type = "sara_format_#{params[:workflow]}".to_sym
    return if exported_recently?(export_type)

    # Clear out old receipts and create a new one
    current_user.export_receipts.where(export_type: export_type).destroy_all
    ExportReceipt.create(user_id: current_user.id, export_type: export_type)

    # Spawn job to handle export
    config = {
      user_id: current_user.id,
      export_type: export_type,
      format: 'xlsx',
      filename: "Sara-Alert-Format-#{params[:workflow]&.titleize}",
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

  def excel_full_history_patients
    # Verify params
    redirect_to(root_url) && return unless %w[purgeable all].include?(params[:scope])

    export_type = "full_history_#{params[:scope]}".to_sym
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

  def excel_full_history_patient
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

    exported_data = get_export_data(patients, config[:data])
    send_data write_export_data_to_files(config, exported_data, nil)[0][:content]
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

    unsanitized_config = params.require(:config).permit(:filename, :format, data: {})
    config = {
      user_id: current_user.id,
      export_type: export_type,
      filename_data_type: false
    }

    # Validate format param
    config[:format] = unsanitized_config.require(:format)
    return head :bad_request unless EXPORT_FORMATS.include?(config[:format])

    # Validate name param (remove os path characters and replace non-ascii characters with dash)
    config[:filename] = params[:name]&.gsub(%r{^.*(\|/)}, '')&.gsub(/[^0-9A-Za-z.\-]/, '-')

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
