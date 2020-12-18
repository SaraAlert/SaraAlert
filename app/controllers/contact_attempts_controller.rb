# frozen_string_literal: true

# ContactAttemptsController: for keeping track of contact attempts over time
class ContactAttemptsController < ApplicationController
  before_action :authenticate_user!

  # Create a new history route; this is used to create comments on subjects.
  def create
    redirect_to root_url unless current_user.can_create_subject_contact_attempt?

    permitted_params = params.permit(:patient_id, :successful, :note)
    patient_id = params.require(:patient_id)
    successful = permitted_params[:successful]
    note = permitted_params[:note]

    ContactAttempt.create!(patient_id: patient_id,
                           user_id: current_user.id,
                           successful: successful,
                           note: note)

    History.create!(patient_id: patient_id,
                    created_by: current_user.email,
                    comment: "#{successful ? 'Successful' : 'Unsuccessful'} contact attempt. Note: #{note}",
                    history_type: 'Contact Attempt')

    redirect_back fallback_location: root_path
  end
end
