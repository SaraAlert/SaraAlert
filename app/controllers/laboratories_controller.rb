# frozen_string_literal: true

# LaboratoriesController: lab results
class LaboratoriesController < ApplicationController
  before_action :authenticate_user!

  # Create a new lab result
  def create
    redirect_to(root_url) && return unless current_user.can_create_patient_laboratories?

    lab = Laboratory.new(lab_type: params.permit(:lab_type)[:lab_type],
                         specimen_collection: params.permit(:specimen_collection)[:specimen_collection],
                         report: params.permit(:report)[:report],
                         result: params.permit(:result)[:result])
    lab.patient_id = params.permit(:patient_id)[:patient_id]
    lab.save!
    History.lab_result(patient: params.permit(:patient_id)[:patient_id],
                       created_by: current_user.email,
                       comment: "User added a new lab result (ID: #{lab.id}).")
  end

  # Update an existing lab result
  def update
    redirect_to(root_url) && return unless current_user.can_edit_patient_laboratories?

    lab = Laboratory.find_by(id: params.permit(:id)[:id])
    lab.update!(lab_type: params.permit(:lab_type)[:lab_type],
                specimen_collection: params.permit(:specimen_collection)[:specimen_collection],
                report: params.permit(:report)[:report],
                result: params.permit(:result)[:result])
    History.lab_result_edit(patient: params.permit(:patient_id)[:patient_id],
                            created_by: current_user.email,
                            comment: "User edited a lab result (ID: #{lab.id}).")
  end
end
