# frozen_string_literal: true

require 'axlsx'

# ExportController: for exporting subjects
class ExportController < ApplicationController
  include ImportExport

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def csv
    # Verify params
    redirect_to(root_url) && return unless params[:workflow] == 'exposure' || params[:workflow] == 'isolation'

    type = "csv_#{params[:workflow]}"

    if current_user.export_receipts.where(export_type: type).where('created_at > ?', 1.hour.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: type)

      # Spawn job to handle export
      ExportJob.perform_later(current_user.id, type)

      respond_to do |format|
        format.any { head :ok }
      end
    end
  end

  def excel_comprehensive_patients
    # Verify params
    redirect_to(root_url) && return unless params[:workflow] == 'exposure' || params[:workflow] == 'isolation'

    type = "sara_format_#{params[:workflow]}"

    if current_user.export_receipts.where(export_type: type).where('created_at > ?', 1.hour.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: type)

      # Spawn job to handle export
      ExportJob.perform_later(current_user.id, type)

      respond_to do |format|
        format.any { head :ok }
      end
    end
  end

  def excel_full_history_patients
    type = "full_history_#{params[:scope] == 'purgeable' ? 'purgeable' : 'all'}"

    if current_user.export_receipts.where(export_type: type).where('created_at > ?', 1.hour.ago).exists?
      render json: { message: 'You have already initiated an export of this type in the last hour. Please try again later.' }.to_json, status: 401
    else
      # Clear out old receipts and create a new one
      current_user.export_receipts.where(export_type: type).destroy_all
      ExportReceipt.create(user_id: current_user.id, export_type: type)

      # Spawn job to handle export
      ExportJob.perform_later(current_user.id, type)

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

  def custom
    permitted_params = params.permit(:file_ext, :fields, :filters)

    # Validate file_type param
    file_type = permitted_params.require(:file_ext).to_sym
    return head :bad_request unless %i[csv xlsx]

    # Validate fields param
    fields = permitted_params.require(:fields)
    return head :bad_request unless fields.kind_of?(Array)
    fields.each do |field|
      return head :bad_request unless PATIENT_FIELDS.keys.include?(field.to_sym)
    end

    # Validate filters
    filters = permitted_params[:filters]

    render json: {}
  end

  private

  def authenticate_user_role
    redirect_to(root_url) && return unless current_user.can_export?
  end
end
