# frozen_string_literal: true

require 'axlsx'

# ExportController: for exporting subjects
class ExportController < ApplicationController
  include ImportExport

  before_action :authenticate_user!

  def csv
    # Verify permissions
    redirect_to(root_url) && return unless current_user.can_export?

    # Verify params
    redirect_to(root_url) && return unless params[:workflow] == 'exposure' || params[:workflow] == 'isolation'

    # Spawn job to handle export
    ExportJob.perform_later(current_user.id, "csv_#{params[:workflow]}")

    respond_to do |format|
      format.any { head :ok }
    end
  end

  def excel_comprehensive_patients
    # Verify permissions
    redirect_to(root_url) && return unless current_user.can_export?

    # Verify params
    redirect_to(root_url) && return unless params[:workflow] == 'exposure' || params[:workflow] == 'isolation'

    # Spawn job to handle export
    ExportJob.perform_later(current_user.id, "sara_format_#{params[:workflow]}")

    respond_to do |format|
      format.any { head :ok }
    end
  end

  def excel_full_history_patients
    redirect_to(root_url) && return unless current_user.can_export?

    # Spawn job to handle export
    ExportJob.perform_later(current_user.id, "full_history_#{params[:scope] == 'purgeable' ? 'purgeable' : 'all'}")

    respond_to do |format|
      format.any { head :ok }
    end
  end

  def excel_full_history_patient
    redirect_to(root_url) && return unless current_user.can_export?
    return unless current_user.viewable_patients.exists?(params[:patient_id])

    patients = current_user.viewable_patients.where(id: params[:patient_id])
    return if patients.empty?

    History.monitoree_data_downloaded(patient: patients.first, created_by: current_user.email)
    send_data excel_export(patients)
  end
end
