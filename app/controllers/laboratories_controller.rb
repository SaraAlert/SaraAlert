# frozen_string_literal: true

# LaboratoriesController: lab results
class LaboratoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_can_create, only: %i[create]
  before_action :check_can_edit, only: %i[update destroy]
  before_action :check_patient
  before_action :check_lab, only: %i[update destroy]
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error

  # Create a new lab result
  def create
    lab = Laboratory.new(lab_type: params.permit(:lab_type)[:lab_type],
                         specimen_collection: params.permit(:specimen_collection)[:specimen_collection],
                         report: params.permit(:report)[:report],
                         result: params.permit(:result)[:result])
    lab.patient_id = @patient_id
    lab.save!
    History.lab_result(patient: @patient_id,
                       created_by: current_user.email,
                       comment: "User added a new lab result (ID: #{lab.id}).")
  end

  # Update an existing lab result
  def update
    @lab.update!(lab_type: params.permit(:lab_type)[:lab_type],
                 specimen_collection: params.permit(:specimen_collection)[:specimen_collection],
                 report: params.permit(:report)[:report],
                 result: params.permit(:result)[:result])

    History.lab_result_edit(patient: @patient_id,
                            created_by: current_user.email,
                            comment: "User edited a lab result (ID: #{@lab.id}).")
  end

  # Destroy an existing lab result
  def destroy
    @lab.destroy
    if @lab.destroyed?
      reason = params.permit(:delete_reason)[:delete_reason]
      comment = "User deleted a lab result (ID: #{@lab.id}"
      comment += ", Type: #{@lab.lab_type}" unless @lab.lab_type.blank?
      comment += ", Specimen Collected: #{@lab.specimen_collection}" unless @lab.specimen_collection.blank?
      comment += ", Report: #{@lab.report}" unless @lab.report.blank?
      comment += ", Result: #{@lab.result}" unless @lab.result.blank?
      comment += "). Reason: #{reason}."
      History.lab_result_edit(patient: @patient_id,
                              created_by: current_user.email,
                              comment: comment)
    else
      render status: 500
    end
  end

  private

  def check_can_create
    return head :forbidden unless current_user.can_create_patient_laboratories?
  end

  def check_can_edit
    return head :forbidden unless current_user.can_edit_patient_laboratories?
  end

  def check_patient
    @patient_id = params.permit(:patient_id)[:patient_id]&.to_i

    # Check if Patient ID is valid
    unless Patient.exists?(@patient_id)
      error_message = "Lab result cannot be modified for unknown monitoree with ID: #{@patient_id}"
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # Check if user has access to patient
    return if current_user.get_patient(@patient_id)

    error_message = "User does not have access to Patient with ID: #{@patient_id}"
    render(json: { error: error_message }, status: :forbidden) && return
  end

  def check_lab
    @lab = Laboratory.find_by(id: params.permit(:id)[:id])
    return head :bad_request if @lab.nil?
  end

  def handle_validation_error(error)
    render(json: error.record.errors, status: 422)
  end
end
