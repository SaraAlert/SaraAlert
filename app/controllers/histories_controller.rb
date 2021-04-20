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
  end

  def update
    redirect_to root_url unless current_user.can_create_subject_history?
    history = current_user.get_histories(params.permit(:id)[:id])
    redirect_to root_url && return if history.nil? || history.history_type != 'Comment' || history.created_by != current_user.email
    history.comment = params.permit(:comment)[:comment]
    history.was_edited = true
    history.save!
    render json: history
  end

  def destroy
    redirect_to root_url unless current_user.can_create_subject_history?
    history = current_user.get_histories(params.permit(:id)[:id])
    redirect_to root_url && return if history.nil? || history.history_type != 'Comment' || history.created_by != current_user.email
    history.destroy
  end
end
