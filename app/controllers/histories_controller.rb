# frozen_string_literal: true

# HistoriesController: for keeping track of user actions over time
class HistoriesController < ApplicationController
  before_action :authenticate_user!, :check_role, :check_patient
  before_action :check_history, only: %i[edit delete]

  # Create a new history route; this is used to create comments on subjects.
  def create
    history = History.new(patient_id: @patient.id,
                          created_by: current_user.email,
                          comment: params.permit(:comment)[:comment],
                          history_type: params.permit(:history_type)[:history_type] || History::HISTORY_TYPES[:comment])

    history.original_comment = history if history.history_type == History::HISTORY_TYPES[:comment]

    # Handle case where history comment create failed
    render(json: { error: 'Comment was unable to be created.' }, status: :bad_request) && return unless history.save
  end

  # "Edits" a history comment - a new history comment is created with the updated comment text and a reference to the id of the original
  def edit
    history = History.new(patient_id: @patient.id,
                          created_by: current_user.email,
                          comment: params.permit(:comment)[:comment],
                          history_type: History::HISTORY_TYPES[:comment],
                          original_comment_id: @history.original_comment_id)

    # Handle case where history comment edit failed
    render(json: { error: 'Comment was unable to be edited.' }, status: :bad_request) && return unless history.save
  end

  # "Deletes" a history comment - does not actually remove the comment from the database
  # but adds a deleted_by and deleted_reason that show the comment was deleted
  # rubocop:disable Rails/SkipsModelValidations
  def delete
    # mark each version of the history as deleted, not just the most recent one
    @patient.histories
            .where(original_comment_id: @history.original_comment_id)
            .update_all({ deleted_by: current_user.email, delete_reason: params.permit(:delete_reason)[:delete_reason], updated_at: DateTime.now })
  end
  # rubocop:enable Rails/SkipsModelValidations

  private

  def check_role
    return head :forbidden unless current_user.can_create_subject_history?
  end

  def check_patient
    # Check if Patient ID is valid
    patient_id = params.require(:patient_id)&.to_i
    unless Patient.exists?(patient_id)
      render(json: { error: "History comment cannot be modified for unknown monitoree with ID: #{patient_id}" },
             status: :bad_request) && return
    end

    # Check if user has access to patient
    @patient = current_user.viewable_patients.find_by(id: patient_id)
    render(json: { error: "User does not have access to Patient with ID: #{patient_id}" }, status: :forbidden) && return unless @patient
  end

  def check_history
    @history = @patient.histories.find_by(id: params.require(:id))
    return head :bad_request if @history.nil? || @history.history_type != History::HISTORY_TYPES[:comment]
  end
end
