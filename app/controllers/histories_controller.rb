# frozen_string_literal: true

# HistoriesController: for keeping track of user actions over time
class HistoriesController < ApplicationController
  before_action :authenticate_user!

  # Create a new history route; this is used to create comments on subjects.
  def create
    redirect_to root_url unless current_user.can_create_subject_history?

    History.create!(patient_id: params.permit(:patient_id)[:patient_id],
                    created_by: current_user.email,
                    comment: params.permit(:comment)[:comment],
                    history_type: params.permit(:type)[:type] || 'Comment')

    # Increment number of contact attempts if applicable
    if params.permit(:type)[:type] == 'Contact Attempt'
      patient = current_user.patients.find(params.permit(:patient_id)[:patient_id])
      if params.permit(:comment)[:comment].downcase.include?('unsuccessful')
        patient&.update(contact_attempts: patient.contact_attempts + 1, contact_attempts_unsuccessful: patient.contact_attempts_unsuccessful + 1)
      else
        patient&.update(contact_attempts: patient.contact_attempts + 1, contact_attempts_successful: patient.contact_attempts_successful + 1)
      end
    end

    redirect_back fallback_location: root_path
  end
end
