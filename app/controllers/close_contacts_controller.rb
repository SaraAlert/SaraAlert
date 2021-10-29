# frozen_string_literal: true

# CloseContactsController: close contacts
class CloseContactsController < ApplicationController
  include CloseContactQueryHelper

  before_action :authenticate_user!
  before_action :check_can_create, only: %i[create]
  before_action :check_can_edit, only: %i[update destroy]
  before_action :check_patient
  before_action :check_close_contact, only: %i[update destroy]

  def index
    # Validate params and handle errors if invalid
    begin
      data = validate_close_contact_query(params)
    rescue StandardError => e
      render(json: { error: e.message }, status: :bad_request) && return
    end

    # @patient is set in the check_patient hook above
    close_contacts = @patient.close_contacts

    # Get close_contacts table data
    close_contacts = search(close_contacts, data[:search_text])
    close_contacts = sort(close_contacts, data[:sort_order], data[:sort_direction])
    close_contacts = paginate(close_contacts, data[:entries], data[:page])

    render json: { table_data: close_contacts, total: close_contacts.total_entries }
  end

  # Create a new close contact
  def create
    cc = CloseContact.new(first_name: params.permit(:first_name)[:first_name],
                          last_name: params.permit(:last_name)[:last_name],
                          primary_telephone: params.permit(:primary_telephone)[:primary_telephone],
                          email: params.permit(:email)[:email],
                          last_date_of_exposure: params.permit(:last_date_of_exposure)[:last_date_of_exposure],
                          assigned_user: params.permit(:assigned_user)[:assigned_user],
                          notes: params.permit(:notes)[:notes],
                          enrolled_id: nil,
                          contact_attempts: 0)
    cc.patient_id = @patient.id
    ActiveRecord::Base.transaction do
      if cc.save
        History.close_contact(patient: params.permit(:patient_id)[:patient_id],
                              created_by: current_user.email,
                              comment: "User added a new close contact (ID: #{cc.id}).")
      else
        # Handle case where close contact create failed
        error_message = 'Close Contact was unable to be created.'
        render(json: { error: error_message }, status: :bad_request) && return
      end
    end
  end

  # Update an existing close contact
  def update
    update_params = {
      first_name: params.permit(:first_name)[:first_name],
      last_name: params.permit(:last_name)[:last_name],
      primary_telephone: params.permit(:primary_telephone)[:primary_telephone],
      email: params.permit(:email)[:email],
      last_date_of_exposure: params.permit(:last_date_of_exposure)[:last_date_of_exposure],
      assigned_user: params.permit(:assigned_user)[:assigned_user],
      notes: params.permit(:notes)[:notes],
      contact_attempts: params.permit(:contact_attempts)[:contact_attempts]
    }
    ActiveRecord::Base.transaction do
      if @close_contact.update(update_params)
        History.close_contact_edit(patient: @patient.id,
                                   created_by: current_user.email,
                                   comment: "User edited a close contact (ID: #{@close_contact.id}).")
      else
        # Handle case where close contact update failed
        error_message = 'Close Contact was unable to be updated.'
        render(json: { error: error_message }, status: :bad_request) && return
      end
    end
  end

  # Delete an existing close contact record
  def destroy
    ActiveRecord::Base.transaction do
      if @close_contact.destroy
        reason = params.require(:delete_reason)
        comment = "User deleted a close contact (ID: #{@close_contact.id}"
        comment += ", Name: #{@close_contact.first_name} #{@close_contact.last_name}" if (@close_contact.first_name + @close_contact.last_name).present?
        comment += ", Primary Telephone: #{@close_contact.primary_telephone}" if @close_contact.primary_telephone.present?
        comment += ", Email: #{@close_contact.email}" if @close_contact.email.present?
        if @close_contact.last_date_of_exposure.present?
          comment += ", Last Date of Exposure: #{@close_contact.last_date_of_exposure.to_date.strftime('%m/%d/%Y')}"
        end
        comment += ", Assigned User: #{@close_contact.assigned_user}" if @close_contact.assigned_user.present?
        comment += ", Notes: #{@close_contact.notes}" if @close_contact.notes.present?
        comment += ", Contact Attempts: #{@close_contact.contact_attempts}" if @close_contact.contact_attempts.present?
        comment += ", Enrolled: #{@close_contact.enrolled_id.blank? ? 'No' : 'Yes, Sara Alert ID ' + @close_contact.enrolled_id.to_s}"
        comment += "). Reason: #{reason}."
        History.close_contact_edit(patient: @patient.id,
                                   created_by: current_user.email,
                                   comment: comment)
      else
        # Handle case where close contact delete failed
        error_message = 'Close Contact was unable to be deleted.'
        render(json: { error: error_message }, status: :bad_request) && return
      end
    end
  end

  private

  def check_can_create
    return head :forbidden unless current_user.can_create_patient_close_contacts?
  end

  def check_can_edit
    return head :forbidden unless current_user.can_edit_patient_close_contacts?
  end

  def check_patient
    patient_id = params.require(:patient_id).to_i
    # Check if Patient ID is valid
    unless Patient.exists?(patient_id)
      error_message = "Unknown patient with ID: #{patient_id}"
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # Check if user has access to patient
    @patient = current_user.viewable_patients.find_by(id: patient_id)
    render(json: { error: "User does not have access to Patient with ID: #{patient_id}" }, status: :forbidden) && return unless @patient
  end

  def check_close_contact
    @close_contact = @patient.close_contacts.find_by(id: params.require(:id))
    return head :bad_request if @close_contact.nil?
  end
end
