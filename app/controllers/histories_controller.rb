class HistoriesController < ApplicationController
  before_action :authenticate_user!

  def create
    redirect_to root_url unless current_user.can_create_subject_history?
    history = History.new(comment: params.permit(:comment)[:comment])
    history.created_by = current_user.email
    patient = Patient.find_by_id(params.permit(:patient_id)[:patient_id])
    history.patient = patient
    history.history_type = 'comment'
    history.save!
    redirect_back fallback_location: root_path
  end

end
