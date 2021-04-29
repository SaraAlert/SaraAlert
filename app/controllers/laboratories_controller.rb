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
    lab = Laboratory.find_by(id: params.permit(:id)[:id])
    lab.destroy
    if lab.destroyed?
      reason = params.permit(:reason)[:reason]
      History.lab_result_edit(patient: params.permit(:patient_id)[:patient_id],
      created_by: current_user.email,
      comment: "User deleted a lab result (ID: #{lab.id}, Type: #{lab.lab_type}, Specimen Collected: #{lab.specimen_collection}, Report: #{lab.report}, Result: #{lab.result}) For Reason: #{reason}.")
    else
      render status: 500
    end
  end

end
