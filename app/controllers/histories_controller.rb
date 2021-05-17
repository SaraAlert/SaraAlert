# frozen_string_literal: true

# HistoriesController: for keeping track of user actions over time
class HistoriesController < ApplicationController
  before_action :authenticate_user!

  # Create a new history route; this is used to create comments on subjects.
  def create
    redirect_to root_url unless current_user.can_create_subject_history?

    patient_id = params.permit(:patient_id)[:patient_id]

    redirect_to(root_url) && return if patient_id.nil?

    redirect_to(root_url) && return unless current_user.viewable_patients.where(id: patient_id).exists?

    History.create!(patient_id: patient_id,
                    created_by: current_user.email,
                    comment: params.permit(:comment)[:comment],
                    history_type: params.permit(:type)[:type] || 'Comment')
  end
end
