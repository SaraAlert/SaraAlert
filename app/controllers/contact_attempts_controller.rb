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
    apply_to_household_ids = params.permit(apply_to_household_ids: [])[:apply_to_household_ids]

    redirect_to(root_url) && return if patient_id.nil?

    redirect_to(root_url) && return unless current_user.viewable_patients.where(id: patient_id).exists?

    household_ids = [patient_id]
    household_ids.concat apply_to_household_ids unless apply_to_household_ids.empty?

    household_ids.each do |id|
      ContactAttempt.create!(patient_id: id,
                             user_id: current_user.id,
                             successful: successful,
                             note: note)

      History.create!(patient_id: id,
                      created_by: current_user.email,
                      comment: "#{successful ? 'Successful' : 'Unsuccessful'} contact attempt. Note: #{note}",
                      history_type: 'Manual Contact Attempt')
    end
  end
end
