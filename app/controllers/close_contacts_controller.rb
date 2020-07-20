# frozen_string_literal: true

# CloseContactsController: close contacts
class CloseContactsController < ApplicationController
  before_action :authenticate_user!

  # Create a new close contact
  def create
    redirect_to root_url && return unless current_user.can_create_patient_close_contacts?
    cc = CloseContact.new(first_name: params.permit(:first_name)[:first_name],
                          last_name: params.permit(:last_name)[:last_name],
                          primary_telephone: params.permit(:primary_telephone)[:primary_telephone],
                          email: params.permit(:email)[:email],
                          notes: params.permit(:notes)[:notes],
                          enrolled_id: nil,
                          contact_attempts: 0)
    cc.patient_id = params.permit(:patient_id)[:patient_id]
    cc.save
  end

  # Update an existing close contact
  def update
    redirect_to root_url && return unless current_user.can_edit_patient_close_contacts?
    cc = CloseContact.find_by(id: params.permit(:id)[:id])
    cc.update(first_name: params.permit(:first_name)[:first_name],
              last_name: params.permit(:last_name)[:last_name],
              primary_telephone: params.permit(:primary_telephone)[:primary_telephone],
              email: params.permit(:email)[:email],
              notes: params.permit(:notes)[:notes],
              contact_attempts: params.permit(:contact_attempts)[:contact_attempts])
    cc.save
  end
end
