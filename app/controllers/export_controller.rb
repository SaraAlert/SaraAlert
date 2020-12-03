# frozen_string_literal: true

require 'axlsx'

# ExportController: for exporting subjects
class ExportController < ApplicationController
  include ImportExport
  include PatientQueryHelper
  include AssessmentQueryHelper
  include LaboratoryQueryHelper
  include CloseContactQueryHelper
  include TransferQueryHelper
  include HistoryQueryHelper

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def csv
    # Verify params
    redirect_to(root_url) && return unless %w[exposure isolation].include?(params[:workflow])

    export_type = "csv_#{params[:workflow]}".to_sym

    if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.hour.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: export_type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: export_type)

      # Spawn job to handle export
      config = {
        user_id: current_user.id,
        export_type: export_type,
        format: 'csv',
        data: {
          patients: {
            checked: LINELIST_FIELDS,
            query: { workflow: params[:workflow] }
          }
        }
      }

      ExportJob.perform_later(config)

      respond_to do |format|
        format.any { head :ok }
      end
    end
  end

  def excel_comprehensive_patients
    # Verify params
    redirect_to(root_url) && return unless %w[exposure isolation].include?(params[:workflow])

    export_type = "sara_format_#{params[:workflow]}".to_sym

    if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.hour.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: export_type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: export_type)

      # Spawn job to handle export
      config = {
        user_id: current_user.id,
        export_type: export_type,
        format: 'xlsx',
        data: {
          patients: {
            checked: COMPREHENSIVE_FIELDS,
            query: { workflow: params[:workflow] }
          }
        }
      }

      ExportJob.perform_later(config)

      respond_to do |format|
        format.any { head :ok }
      end
    end
  end

  def excel_full_history_patients
    # Verify params
    redirect_to(root_url) && return unless %w[purgeable all].include?(params[:scope])

    export_type = "full_history_#{params[:scope]}".to_sym

    if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.hour.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: export_type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: export_type)

      # Spawn job to handle export
      config = {
        user_id: current_user.id,
        export_type: export_type,
        format: 'xlsx',
        data: {
          patients: {
            checked: COMPREHENSIVE_FIELDS,
            query: { workflow: params[:workflow] }
          },
          assessments: {
            checked: ALL_FIELDS_NAMES[:assessments].keys,
            query: {}
          },
          laboratories: {
            checked: ALL_FIELDS_NAMES[:laboratories].keys,
            query: {}
          },
          close_contacts: {
            checked: ALL_FIELDS_NAMES[:close_contacts].keys,
            query: {}
          },
          transfers: {
            checked: ALL_FIELDS_NAMES[:transfers].keys,
            query: {}
          },
          histories: {
            checked: ALL_FIELDS_NAMES[:histories].keys,
            query: {}
          }
        }
      }

      ExportJob.perform_later(config)

      respond_to do |format|
        format.any { head :ok }
      end
    end
  end

  def excel_full_history_patient
    return unless current_user.viewable_patients.exists?(params[:patient_id])

    patients = current_user.viewable_patients.where(id: params[:patient_id])
    return if patients.empty?

    History.monitoree_data_downloaded(patient: patients.first, created_by: current_user.email)
    send_data excel_export(patients)
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

    # if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.hour.ago).exists?
    if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.second.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      unsanitized_config = params.require(:config).permit(:filename, :format, data: {})
      config = {
        user_id: current_user.id,
        export_type: export_type
      }

      # Validate format param
      config[:format] = unsanitized_config.require(:format)
      return head :bad_request unless EXPORT_FORMATS.include?(config[:format])

      # Validate filename param (remove os path characters and replace non-ascii characters with underscore)
      config[:filename] = unsanitized_config[:filename]&.gsub(%r{^.*(\|/)}, '')&.gsub(/[^0-9A-Za-z.\-]/, '_')

      # Validate data
      data = unsanitized_config.require(:data)
      begin
        config[:data] = {
          patients: {
            checked: validate_checked_fields(data, :patients),
            query: validate_patients_query(data.require(:patients)[:query])
          },
          assessments: {
            checked: validate_checked_fields(data, :assessments),
            query: validate_assessments_query(data.require(:assessments)[:query])
          },
          laboratories: {
            checked: validate_checked_fields(data, :laboratories),
            query: validate_laboratories_query(data.require(:laboratories)[:query])
          },
          close_contacts: {
            checked: validate_checked_fields(data, :close_contacts),
            query: validate_close_contacts_query(data.require(:close_contacts)[:query])
          },
          transfers: {
            checked: validate_checked_fields(data, :transfers),
            query: validate_transfers_query(data.require(:transfers)[:query])
          },
          histories: {
            checked: validate_checked_fields(data, :histories),
            query: validate_histories_query(data.require(:histories)[:query])
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
  end

  private

  def validate_checked_fields(data, data_type)
    unsanitized_checked = data.require(data_type).require(:checked)
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
