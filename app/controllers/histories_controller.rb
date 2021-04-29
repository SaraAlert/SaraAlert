# frozen_string_literal: true

# HistoriesController: for keeping track of user actions over time
class HistoriesController < ApplicationController
  before_action :authenticate_user!

  # Create a new history route; this is used to create comments on subjects.
  def create
    redirect_to root_url unless current_user.can_create_subject_history?

    history = History.new(patient_id: params.permit(:patient_id)[:patient_id],
                          created_by: current_user.email,
                          comment: params.permit(:comment)[:comment],
                          history_type: params.permit(:type)[:type] || 'Comment')

    history.original_comment = history

    # Attempt to save and continue; else if failed redirect to index
    render(json: history.errors, status: 422) && return unless history.save

    render(json: history) && return
  end

  def edit
    redirect_to root_url unless current_user.can_create_subject_history?

    history = current_user.get_histories(params.permit(:id)[:id])
    redirect_to root_url && return if history.nil? || history.history_type != 'Comment' || history.created_by != current_user.email

    History.create!(patient_id: history.patient_id,
                    created_by: current_user.email,
                    comment: params.permit(:comment)[:comment],
                    history_type: params.permit(:type)[:type] || 'Comment',
                    original_comment_id: history.original_comment_id)
  end

  def archive
    redirect_to root_url unless current_user.can_create_subject_history?

    history = current_user.get_histories(params.permit(:id)[:id])
    redirect_to root_url && return if history.nil? || history.history_type != 'Comment' || history.created_by != current_user.email

    history.archived = true
    history.archived_by = current_user.email
    history.save!
    render json: history
  end
end
