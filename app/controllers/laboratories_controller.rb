# frozen_string_literal: true

# LaboratoriesController: lab results
class LaboratoriesController < ApplicationController
  before_action :authenticate_user!

  # Create a new lab result
  def create
    redirect_to(root_url) && return unless current_user.can_create_patient_laboratories?

    patient_id = params.permit(:patient_id)[:patient_id]

    redirect_to(root_url) && return if patient_id.nil?

    redirect_to(root_url) && return unless current_user.viewable_patients.where(id: patient_id).exists?
    # Check if Patient ID is valid
    unless Patient.exists?(patient_id)
      error_message = "Lab Result cannot be created for unknown monitoree with ID: #{patient_id}"
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # Check if user has access to patient
    unless current_user.get_patient(patient_id)
      error_message = "User does not have access to Patient with ID: #{patient_id}"
      render(json: { error: error_message }, status: :forbidden) && return
    end

    lab = Laboratory.new(lab_type: params.permit(:lab_type)[:lab_type],
                         specimen_collection: params.permit(:specimen_collection)[:specimen_collection],
                         report: params.permit(:report)[:report],
                         result: params.permit(:result)[:result])
    lab.patient_id = patient_id
    lab.save!
    History.lab_result(patient: patient_id,
                       created_by: current_user.email,
                       comment: "User added a new lab result (ID: #{lab.id}).")
  end

  # Update an existing lab result
  def update
    redirect_to(root_url) && return unless current_user.can_edit_patient_laboratories?

    patient_id = params.permit(:patient_id)[:patient_id]

    redirect_to(root_url) && return if patient_id.nil?

    redirect_to(root_url) && return unless current_user.viewable_patients.where(id: patient_id).exists?
    # Check if Patient ID is valid
    unless Patient.exists?(patient_id)
      error_message = "Lab Result cannot be updated for unknown monitoree with ID: #{patient_id}"
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # Check if user has access to patient
    unless current_user.get_patient(patient_id)
      error_message = "User does not have access to Patient with ID: #{patient_id}"
      render(json: { error: error_message }, status: :forbidden) && return
    end

    lab = Laboratory.find_by(id: params.permit(:id)[:id])
    lab.update!(lab_type: params.permit(:lab_type)[:lab_type],
                specimen_collection: params.permit(:specimen_collection)[:specimen_collection],
                report: params.permit(:report)[:report],
                result: params.permit(:result)[:result])

    History.lab_result_edit(patient: patient_id,
                            created_by: current_user.email,
                            comment: "User edited a lab result (ID: #{lab.id}).")
  end

  # Delete an existing lab result
  def destroy
    redirect_to(root_url) && return unless current_user.can_edit_patient_laboratories?

    patient_id = params.permit(:patient_id)[:patient_id]

    # Check if Patient ID is valid
    unless Patient.exists?(patient_id)
      error_message = "Lab Result cannot be deleted for unknown monitoree with ID: #{patient_id}"
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # Check if user has access to patient
    unless current_user.get_patient(patient_id)
      error_message = "User does not have access to Patient with ID: #{patient_id}"
      render(json: { error: error_message }, status: :forbidden) && return
    end

    lab = Laboratory.find_by(id: params.permit(:id)[:id])
    lab.destroy
    if lab.destroyed?
      reason = params.permit(:delete_reason)[:delete_reason]
      comment = "User deleted a lab result (ID: #{lab.id}"
      comment += ", Type: #{lab.lab_type}" unless lab.lab_type.blank?
      comment += ", Specimen Collected: #{lab.specimen_collection}" unless lab.specimen_collection.blank?
      comment += ", Report: #{lab.report}" unless lab.report.blank?
      comment += ", Result: #{lab.result}" unless lab.result.blank?
      comment += "). Reason: #{reason}."
      History.lab_result_edit(patient: patient_id,
                              created_by: current_user.email,
                              comment: comment)
    else
      render status: 500
    end
  end
end
