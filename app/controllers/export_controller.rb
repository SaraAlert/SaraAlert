# frozen_string_literal: true

require 'axlsx'

# ExportController: for exporting subjects
class ExportController < ApplicationController
  include ImportExport
  include PatientQueryHelper

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def csv
    permitted_params = params.permit(:workflow, :tab, :jurisdiction, :scope, :user, :search, :order, :direction, :filter)

    export_type = "Sara-Alert-Linelist-#{params[:workflow].capitalize}"

    if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.hour.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      # Validate filters
      begin
        filters = validate_patients_query(permitted_params)
      rescue StandardError
        return head :bad_request
      end

      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: export_type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: export_type)

      # Spawn job to handle export
      ExportJob.perform_later(current_user.id, export_type, 'csv', LINELIST_FIELDS, filters)

      respond_to do |format|
        format.any { head :ok }
      end
    end
  end

  def excel_comprehensive_patients
    permitted_params = params.permit(:workflow, :tab, :jurisdiction, :scope, :user, :search, :order, :direction, :filter)

    export_type = "Sara-Alert-Format-#{params[:workflow].capitalize}"

    if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.hour.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      # Validate filters
      begin
        filters = validate_patients_query(permitted_params)
      rescue StandardError
        return head :bad_request
      end

      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: export_type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: export_type)

      # Spawn job to handle export
      ExportJob.perform_later(current_user.id, export_type, 'xlsx', COMPREHENSIVE_FIELDS, filters)

      respond_to do |format|
        format.any { head :ok }
      end
    end
  end

  def excel_full_history_patients
    permitted_params = params.permit(:workflow, :tab, :jurisdiction, :scope, :user, :search, :order, :direction, :filter)

    export_type = "Sara-Alert-#{params[:scope] == 'purgeable' ? 'Purge-Eligible' : 'Full'}-Export-Monitorees"

    if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.hour.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      # Validate filters
      begin
        filters = validate_patients_query(permitted_params)
      rescue StandardError
        return head :bad_request
      end

      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: export_type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: export_type)

      # Spawn job to handle export
      ExportJob.perform_later(current_user.id, export_type, 'xlsx', COMPREHENSIVE_FIELDS, filters)

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
    export_type = 'Sara-Alert-Custom-Export'

    # Figure out how to limit exports (1 hour limit might be annoying to users for custom export)
    # if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.hour.ago).exists?
    if current_user.export_receipts.where(export_type: export_type).where('created_at > ?', 1.second.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      config = params.require(:config).permit(:filename, :format, data: {})

      # Validate format param
      format = config.require(:format)
      return head :bad_request unless EXPORT_FORMATS.include?(format)

      # Validate data
      data = config.require(:data)
      patients_query = data.require(:patients).require(:query).permit(:workflow, :tab, :jurisdiction, :scope, :user, :search, :order, :direction, :filter)
      patients_checked = data.require(:patients).require(:checked)
      begin
        validate_patients_query(patients_query)
        validate_checked_fields(:patients, patients_checked)
      rescue StandardError => e
        return render json: e, status: :bad_request
      end

      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: export_type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: export_type)

      # Spawn job to handle export
      ExportJob.perform_later(current_user.id, 'Custom', config)

      respond_to do |f|
        f.any { head :ok }
      end
    end
  end

  private

  def validate_checked_fields(data_type, checked)
    raise StandardError('Checked must be an array') unless checked.is_a?(Array)

    checked.map(&:to_sym).each do |field|
      raise StandardError("Unknown field '#{field}' for '#{data_type}'") unless ALL_FIELDS_NAMES[data_type].keys.include?(field)
    end
  end

  def authenticate_user_role
    redirect_to(root_url) && return unless current_user.can_export?
  end
end
