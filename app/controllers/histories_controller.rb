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

  # "Edits" a history comment - a new history comment is created with the updated comment text and a reference to the id of the original
  def edit
    redirect_to root_url unless current_user.can_create_subject_history?

    patient = current_user.viewable_patients.find_by(id: params.permit(:patient_id)[:patient_id])
    history = patient.histories.find_by(id: params.permit(:id)[:id])
    redirect_to root_url && return if history.nil? || history.history_type != 'Comment' || history.created_by != current_user.email

    History.create!(patient_id: history.patient_id,
                    created_by: current_user.email,
                    comment: params.permit(:comment)[:comment],
                    history_type: params.permit(:type)[:type] || 'Comment',
                    original_comment_id: history.original_comment_id)
  end

  # "Deletes" a history comment - does not actually remove the comment from the database
  # but adds a deleted_by and deleted_reason that show the comment was deleted
  def delete
    redirect_to root_url unless current_user.can_create_subject_history?

    patient = current_user.viewable_patients.find_by(id: params.permit(:patient_id)[:patient_id])
    history = patient.histories.find_by(id: params.permit(:id)[:id])
    redirect_to root_url && return if history.nil? || history.history_type != 'Comment' || history.created_by != current_user.email

    # mark each version of the history as deleted, not just the most recent one
    history_versions = patient.histories.where(original_comment_id: history.original_comment_id)

    history_versions.each do |h|
      h.deleted_by = current_user.email
      h.delete_reason = params.permit(:delete_reason)[:delete_reason]
      h.save!
    end
  end
end
