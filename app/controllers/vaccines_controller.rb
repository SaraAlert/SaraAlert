# frozen_string_literal: true

# VaccinesController: patient immunizations
class VaccinesController < ApplicationController
  include VaccineQueryHelper
  include ValidationHelper

  before_action :authenticate_user!
  before_action :check_can_create, only: %i[create]
  before_action :check_can_edit, only: %i[update destroy]
  before_action :check_patient
  before_action :check_vaccine, only: %i[update destroy]

  def index
    # Validate params and handle errors if invalid
    begin
      data = validate_vaccines_query(params)
    rescue StandardError => e
      render(json: { error: e.message }, status: :bad_request) && return
    end

    vaccines = @patient&.vaccines

    # Get vaccines table data
    vaccines = search(vaccines, data[:search_text])
    vaccines = sort(vaccines, data[:sort_order], data[:sort_direction])
    vaccines = paginate(vaccines, data[:entries], data[:page])

    render json: { table_data: vaccines, total: vaccines.total_entries }
  end

  # Create a new vaccine record
  def create
    # Create the new vaccine
    vaccine = Vaccine.create(
      group_name: params.permit(:group_name)[:group_name],
      product_name: params.permit(:product_name)[:product_name],
      administration_date: params.permit(:administration_date)[:administration_date],
      dose_number: params.permit(:dose_number)[:dose_number],
      notes: params.permit(:notes)[:notes],
      patient_id: @patient.id
    )

    # Handle vaccine creation success or failure
    ActiveRecord::Base.transaction do
      if vaccine.valid?
        # Create history item on successful record creation
        History.vaccination(patient: @patient.id,
                            created_by: current_user.email,
                            comment: "User added a new vaccination (ID: #{vaccine.id}).")
      else
        # Handle case where vaccine create failed
        error_message = 'Vaccination was unable to be created.'
        error_message += " Errors: #{format_model_validation_errors(vaccine).join(', ')}" if vaccine&.errors
        render(json: { error: error_message }, status: :bad_request) && return
      end
    end
  end

  # Update an existing vaccine record
  def update
    update_params = {
      group_name: params.permit(:group_name)[:group_name],
      product_name: params.permit(:product_name)[:product_name],
      administration_date: params.permit(:administration_date)[:administration_date],
      dose_number: params.permit(:dose_number)[:dose_number],
      notes: params.permit(:notes)[:notes],
      patient_id: @patient.id
    }

    # Handle vaccine update success or failure
    ActiveRecord::Base.transaction do
      if @vaccine.update(update_params)
        # Create history item on successful update
        History.vaccination_edit(
          patient: @patient.id,
          created_by: current_user.email,
          comment: "User edited a vaccination (ID: #{@vaccine.id})."
        )
      else
        # Handle case where vaccine update failed
        error_message = 'Vaccination was unable to be updated. '
        error_message += "Errors: #{format_model_validation_errors(@vaccine).join(', ')}" if @vaccine&.errors
        render(json: { error: error_message }, status: :bad_request) && return
      end
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if @vaccine.destroy
        reason = params.permit(:delete_reason)[:delete_reason]
        comment = "User deleted a vaccine (ID: #{@vaccine.id}"
        comment += ", Vaccine Group: #{@vaccine.group_name}" if @vaccine.group_name.present?
        comment += ", Product Name: #{@vaccine.product_name}" if @vaccine.product_name.present?
        comment += ", Administration Date: #{@vaccine.administration_date.strftime('%m/%d/%Y')}" if @vaccine.administration_date.present?
        comment += ", Dose Number: #{@vaccine.dose_number}" if @vaccine.dose_number.present?
        comment += ", Notes: #{@vaccine.notes}" if @vaccine.notes.present?
        comment += "). Reason: #{reason}."
        History.vaccination_edit(patient: @patient.id,
                                 created_by: current_user.email,
                                 comment: comment)
      else
        # Handle case where vaccine destroy failed
        error_message = 'Vaccination was unable to be deleted.'
        render(json: { error: error_message }, status: :bad_request) && return
      end
    end
  end

  private

  def check_can_create
    return head :forbidden unless current_user.can_create_patient_vaccines?
  end

  def check_can_edit
    return head :forbidden unless current_user.can_edit_patient_vaccines?
  end

  def check_patient
    # Check if Patient ID is valid
    patient_id = params.require(:patient_id)&.to_i
    render(json: { error: "Unknown patient with ID #{patient_id}" }, status: :bad_request) && return unless Patient.exists?(patient_id)

    # Check if user has access to patient
    @patient = current_user.viewable_patients.find_by(id: patient_id)
    render(json: { error: "User does not have access to Patient with ID: #{patient_id}" }, status: :forbidden) && return unless @patient
  end

  def check_vaccine
    vaccine_id = params.require(:id)&.to_i
    @vaccine = @patient.vaccines.find_by(id: vaccine_id)
    render(json: { error: "Vaccination with ID #{vaccine_id} cannot be found." }, status: :bad_request) && return unless @vaccine
  end
end
