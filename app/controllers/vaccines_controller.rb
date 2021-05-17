# frozen_string_literal: true

# VaccinesController: patient immunizations
class VaccinesController < ApplicationController
  include VaccineQueryHelper
  include ValidationHelper

  before_action :authenticate_user!, :check_role
  before_action :check_patient, only: %i[create update destroy]
  before_action :check_vaccine, only: %i[update destroy]

  def index
    # Validate params and handle errors if invalid
    begin
      data = validate_vaccines_query(params)
    rescue StandardError => e
      render(json: { error: e.message }, status: :bad_request) && return
    end

    # Verify user has access to patient, patient exists, and the patient has vaccines
    patient = current_user.get_patient(data[:patient_id])
    vaccines = patient&.vaccines
    redirect_to(root_url) && return if patient.nil? || vaccines.blank?

    # Get vaccines table data
    vaccines = search(vaccines, data[:search_text])
    vaccines = sort(vaccines, data[:sort_order], data[:sort_direction])
    vaccines = paginate(vaccines, data[:entries], data[:page])

    render json: { table_data: vaccines, total: vaccines.total_entries }
  end

  # Create a new vaccine record
  def create
    group_name = params.permit(:group_name)[:group_name]
    product_name = params.permit(:product_name)[:product_name]
    administration_date = params.permit(:administration_date)[:administration_date]
    dose_number = params.permit(:dose_number)[:dose_number]
    notes = params.permit(:notes)[:notes]

    # Create the new vaccine
    vaccine = Vaccine.create(
      group_name: group_name,
      product_name: product_name,
      administration_date: administration_date,
      dose_number: dose_number,
      notes: notes,
      patient_id: @patient_id
    )

    # Handle vaccine creation success or failure
    if vaccine.valid?
      # Create history item on successful record creation
      History.vaccination(patient: @patient_id,
                          created_by: current_user.email,
                          comment: "User added a new vaccination (ID: #{vaccine.id}).")
    else
      # Handle case where vaccine create failed
      error_message = 'Vaccination was unable to be created.'
      error_message += " Errors: #{format_model_validation_errors(vaccine).join(', ')}" if vaccine&.errors
      render(json: { error: error_message }, status: :bad_request) && return
    end
  end

  # Update an existing vaccine record
  def update
    group_name = params.permit(:group_name)[:group_name]
    product_name = params.permit(:product_name)[:product_name]
    administration_date = params.permit(:administration_date)[:administration_date]
    dose_number = params.permit(:dose_number)[:dose_number]
    notes = params.permit(:notes)[:notes]

    # Update the vaccine record
    update_params = {
      group_name: group_name,
      product_name: product_name,
      administration_date: administration_date,
      dose_number: dose_number,
      notes: notes,
      patient_id: @patient_id
    }

    # Handle vaccine update success or failure
    if @vaccine.update(update_params)
      # Create history item on successful update
      History.vaccination_edit(
        patient: @patient_id,
        created_by: current_user.email,
        comment: "User edited a vaccination (ID: #{@vaccine.id})."
      )
    else
      # Handle case where vaccine update failed
      error_message = 'Vaccination was unable to be updated. '
      error_message += "Errors: #{format_model_validation_errors(vaccine).join(', ')}" if @vaccine&.errors
      render(json: { error: error_message }, status: :bad_request) && return
    end
  end

  def destroy
    @vaccine.destroy
    if @vaccine.destroyed?
      reason = params.permit(:delete_reason)[:delete_reason]
      comment = "User deleted a vaccine (ID: #{@vaccine.id}"
      comment += ", Vaccine Group: #{@vaccine.group_name}" unless @vaccine.group_name.blank?
      comment += ", Product Name: #{@vaccine.product_name}" unless @vaccine.product_name.blank?
      comment += ", Administration Date: #{@vaccine.administration_date}" unless @vaccine.administration_date.blank?
      comment += ", Dose Number: #{@vaccine.dose_number}" unless @vaccine.dose_number.blank?
      comment += "). Reason: #{reason}."
      History.vaccination_edit(patient: @patient_id,
                              created_by: current_user.email,
                              comment: comment)
    else
      render status: 500
    end
  end

  private

  def check_role
    return head :forbidden unless current_user.can_edit_patient_vaccines?
  end

  def check_patient
    @patient_id = params.permit(:patient_id)[:patient_id]&.to_i

    # Check if Patient ID is valid
    unless Patient.exists?(@patient_id)
      error_message = "Vaccination cannot be created for unknown monitoree with ID: #{@patient_id}"
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # Check if user has access to patient
    unless current_user.get_patient(@patient_id)
      error_message = "User does not have access to Patient with ID: #{@patient_id}"
      render(json: { error: error_message }, status: :forbidden) && return
    end
  end

  def check_vaccine
    @vaccine = Vaccine.find_by(id: params.require(:id)&.to_i)
    render(json: { error: "Vaccination with ID #{@vaccine.ids} cannot be found." }, status: :bad_request) && return unless @vaccine
  end
end
