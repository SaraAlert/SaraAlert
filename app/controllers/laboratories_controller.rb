# frozen_string_literal: true

# LaboratoriesController: lab results
class LaboratoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_can_create, only: %i[create]
  before_action :check_can_edit, only: %i[update destroy]
  before_action :check_patient
  before_action :check_lab, only: %i[update destroy]

  # Create a new lab result
  def create
    lab = Laboratory.new(lab_type: params.permit(:lab_type)[:lab_type],
                         specimen_collection: params.permit(:specimen_collection)[:specimen_collection],
                         report: params.permit(:report)[:report],
                         result: params.permit(:result)[:result],
                         patient_id: @patient.id)

    # Handle lab creation success or failure
    ActiveRecord::Base.transaction do
      if lab.save
        # Create history item on successful create
        History.lab_result(patient: @patient.id,
                           created_by: current_user.email,
                           comment: "User added a new lab result (ID: #{lab.id}).")
      else
        # Handle case where lab create failed
        error_message = 'Lab result was unable to be created.'
        render(json: { error: error_message }, status: :bad_request) && return
      end
    end
  end

  # Update an existing lab result
  def update
    update_params = {
      lab_type: params.permit(:lab_type)[:lab_type],
      specimen_collection: params.permit(:specimen_collection)[:specimen_collection],
      report: params.permit(:report)[:report],
      result: params.permit(:result)[:result]
    }

    # Handle lab update success or failure
    ActiveRecord::Base.transaction do
      if @lab.update(update_params)
        # Create history item on successful update
        History.lab_result_edit(patient: @patient.id,
                                created_by: current_user.email,
                                comment: "User edited a lab result (ID: #{@lab.id}).")
      else
        # Handle case where lab update failed
        error_message = 'Lab result was unable to be updated.'
        render(json: { error: error_message }, status: :bad_request) && return
      end
    end
  end

  # Destroy an existing lab result
  def destroy
    ActiveRecord::Base.transaction do
      if @lab.destroy
        reason = params.permit(:delete_reason)[:delete_reason]
        comment = "User deleted a lab result (ID: #{@lab.id}"
        comment += ", Type: #{@lab.lab_type}" unless @lab.lab_type.blank?
        comment += ", Specimen Collected: #{@lab.specimen_collection}" unless @lab.specimen_collection.blank?
        comment += ", Report: #{@lab.report}" unless @lab.report.blank?
        comment += ", Result: #{@lab.result}" unless @lab.result.blank?
        comment += "). Reason: #{reason}."
        History.lab_result_edit(patient: @patient.id,
                                created_by: current_user.email,
                                comment: comment)
      else
        # Handle case where lab delete failed
        error_message = 'Lab result was unable to be deleted.'
        render(json: { error: error_message }, status: :bad_request) && return
      end
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
    # Check if Patient ID is valid
    patient_id = params.require(:patient_id)&.to_i
    unless Patient.exists?(patient_id)
      render(json: { error: "Lab result cannot be modified for unknown monitoree with ID: #{patient_id}" }, status: :bad_request) && return
    end

    # Check if user has access to patient
    @patient = current_user.viewable_patients.find_by_id(patient_id)
    render(json: { error: "User does not have access to Patient with ID: #{patient_id}" }, status: :forbidden) && return unless @patient
  end

  def check_lab
    @lab = @patient.laboratories.find_by_id(params.require(:id))
    return head :bad_request if @lab.nil?
  end
end
