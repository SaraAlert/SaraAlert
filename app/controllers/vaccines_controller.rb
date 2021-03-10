# frozen_string_literal: true

# VaccinesController: patient immunizations
class VaccinesController < ApplicationController
  include VaccineQueryHelper

  before_action :authenticate_user!

  def index
    redirect_to(root_url) and return unless current_user&.can_view_patient_vaccines?

    # Validate params and handle errors if invalid
    begin
      data = validate_table_query(params)
    rescue StandardError => e
      render(json: { error: e.message }, status: :bad_request) and return
    end

    # Verify user has access to patient, patient exists, and the patient has vaccines
    patient = current_user.get_patient(data[:patient_id])
    vaccines = patient&.vaccines
    redirect_to(root_url) and return if patient.nil? || vaccines.blank?

    # Get vaccines table data
    vaccines = search(vaccines, data[:search_text])
    vaccines = sort(vaccines, data[:sort_order], data[:sort_direction])
    vaccines = paginate(vaccines, data[:entries], data[:page])

    render json: { table_data: vaccines, total: vaccines.total_entries }
  end

  # Create a new vaccine record
  def create
    redirect_to(root_url) and return unless current_user.can_create_patient_vaccines?

    group_name = params.permit(:group_name)[:group_name]
    product_name = params.permit(:product_name)[:product_name]
    administration_date = params.permit(:administration_date)[:administration_date]
    dose_number = params.permit(:dose_number)[:dose_number]
    notes = params.permit(:notes)[:notes]
    patient_id = params.permit(:patient_id)[:patient_id]&.to_i

    # Check if Patient ID is valid
    unless Patient.exists?(patient_id)
      error_message = "Vaccine cannot be created for unknown monitoree with ID: #{patient_id}"
      render(json: { error: error_message }, status: :bad_request) and return
    end

    # Check if user has access to patient
    unless current_user.get_patient(patient_id)
      error_message = "User does not have access to Patient with ID: #{patient_id}"
      render(json: { error: error_message }, status: :forbidden) and return
    end

    # Create the new vaccine
    vaccine = Vaccine.create(
      group_name: group_name,
      product_name: product_name,
      administration_date: administration_date,
      dose_number: dose_number,
      notes: notes,
      patient_id: patient_id
    )

    # Handle vaccine creation success or failure
    if vaccine.valid?
      # Create history item on successful record creation
      History.vaccine(patient: patient_id,
                      created_by: current_user.email,
                      comment: "User added a new vaccine to the monitoree (vaccine ID: #{vaccine.id}).")
    else
      # Handle case where vaccine create failed
      error_message = 'Vaccine was unable to be created.'
      error_message += " Errors: #{vaccine.errors.full_messages.join(',')}" if vaccine&.errors
      render(json: { error: error_message }, status: :bad_request) and return
    end
  end

  # Update an existing vaccine record
  def update
    redirect_to(root_url) and return unless current_user.can_edit_patient_vaccines?

    vaccine_id = params.require(:id)&.to_i
    group_name = params.permit(:group_name)[:group_name]
    product_name = params.permit(:product_name)[:product_name]
    administration_date = params.permit(:administration_date)[:administration_date]
    dose_number = params.permit(:dose_number)[:dose_number]
    notes = params.permit(:notes)[:notes]
    patient_id = params.permit(:patient_id)[:patient_id]&.to_i

    # Check if Patient ID is valid
    unless Patient.exists?(patient_id)
      error_message = "Vaccine cannot be created for unknown monitoree with ID: #{patient_id}"
      render(json: { error: error_message }, status: :bad_request) and return
    end

    # Check if user has access to patient
    unless current_user.get_patient(patient_id)
      error_message = "User does not have access to Patient with ID: #{patient_id}"
      render(json: { error: error_message }, status: :forbidden) and return
    end

    # Get vaccine to update
    vaccine = Vaccine.find_by(id: vaccine_id)

    # Handle case where vaccine cannot be found
    render(json: { error: "Vaccine with ID #{vaccine_id} cannot be found." }, status: :bad_request) and return unless vaccine

    # Update the vaccine record
    update_params = {
      group_name: group_name,
      product_name: product_name,
      administration_date: administration_date,
      dose_number: dose_number,
      notes: notes,
      patient_id: patient_id
    }

    # Handle vaccine update success or failure
    if vaccine.update(update_params)
      # Create history item on successful update
      History.vaccine_edit(
        patient: params.permit(:patient_id)[:patient_id],
        created_by: current_user.email,
        comment: "User edited a vaccine on the monitoree (vaccine ID: #{vaccine_id})."
      )
    else
      # Handle case where vaccine update failed
      error_message = 'Vaccine was unable to be updated. '
      error_message += "Errors: #{vaccine.errors.full_messages.join(',')}" if vaccine&.errors
      render(json: { error: error_message }, status: :bad_request) and return
    end
  end
end
