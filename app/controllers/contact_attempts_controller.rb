# frozen_string_literal: true

# HistoriesController: for keeping track of user actions over time
class HistoriesController < ApplicationController
  before_action :authenticate_user!

  # Create a new history route; this is used to create comments on subjects.
  def create
    redirect_to root_url unless current_user.can_create_subject_contact_attempt?

    permitted_params = params.permit(:patient_id, :successful, :note)

    ContactAttempt.create!(patient_id: params.require(:patient_id),
                           user: current_user.id,
                           successful: permitted_params[:successful],
                           note: permitted_params[:note])

    History.create!(patient_id: params.require(:patient_id),
                    created_by: current_user.email,
                    comment: "#{permitted_params[:successful] ? 'Successful' : 'Unsuccessful'} contact attempt. Note: #{permitted_params[:note]}",
                    history_type: 'Contact Attempt')

    redirect_back fallback_location: root_path
  end
end
