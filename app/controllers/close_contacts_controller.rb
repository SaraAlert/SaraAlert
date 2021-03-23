# frozen_string_literal: true

# CloseContactsController: close contacts
class CloseContactsController < ApplicationController
  include CloseContactQueryHelper

  before_action :authenticate_user!

  def index
    redirect_to(root_url) && return unless current_user&.can_view_patient_close_contacts?

    # Validate params and handle errors if invalid
    begin
      data = validate_close_contact_query(params)
    rescue StandardError => e
      render(json: { error: e.message }, status: :bad_request) && return
    end

    # Verify user has access to patient, patient exists, and the patient has close_contacts
    patient = current_user.get_patient(data[:patient_id])
    close_contacts = CloseContact.where(patient_id: patient.id)
    redirect_to(root_url) && return if patient.nil? || close_contacts.nil?

    # Get close_contacts table data
    close_contacts = search(close_contacts, data[:search_text])
    close_contacts = sort(close_contacts, data[:sort_order], data[:sort_direction])
    close_contacts = paginate(close_contacts, data[:entries], data[:page])

    render json: { table_data: close_contacts, total: close_contacts.count }
  end

  # Create a new close contact
  def create
    redirect_to(root_url) && return unless current_user.can_create_patient_close_contacts?

    cc = CloseContact.new(first_name: params.permit(:first_name)[:first_name],
                          last_name: params.permit(:last_name)[:last_name],
                          primary_telephone: params.permit(:primary_telephone)[:primary_telephone],
                          email: params.permit(:email)[:email],
                          last_date_of_exposure: params.permit(:last_date_of_exposure)[:last_date_of_exposure],
                          assigned_user: params.permit(:assigned_user)[:assigned_user],
                          notes: params.permit(:notes)[:notes],
                          enrolled_id: nil,
                          contact_attempts: 0)
    cc.patient_id = params.permit(:patient_id)[:patient_id]
    cc.save
    History.close_contact(patient: params.permit(:patient_id)[:patient_id],
                          created_by: current_user.email,
                          comment: "User added a new close contact (ID: #{cc.id}).")
  end

  # Update an existing close contact
  def update
    redirect_to(root_url) && return unless current_user.can_edit_patient_close_contacts?

    cc = CloseContact.find_by(id: params.permit(:id)[:id])
    cc.update(first_name: params.permit(:first_name)[:first_name],
              last_name: params.permit(:last_name)[:last_name],
              primary_telephone: params.permit(:primary_telephone)[:primary_telephone],
              email: params.permit(:email)[:email],
              last_date_of_exposure: params.permit(:last_date_of_exposure)[:last_date_of_exposure],
              assigned_user: params.permit(:assigned_user)[:assigned_user],
              notes: params.permit(:notes)[:notes],
              contact_attempts: params.permit(:contact_attempts)[:contact_attempts])
    cc.save
    History.close_contact_edit(patient: params.permit(:patient_id)[:patient_id],
                               created_by: current_user.email,
                               comment: "User edited a close contact (ID: #{cc.id}).")
  end
end
