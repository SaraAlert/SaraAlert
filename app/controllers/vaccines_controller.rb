# frozen_string_literal: true

# VaccinesController: Vaccine records
class VaccinesController < ApplicationController
  before_action :authenticate_user!

  # create a new vaccine record
  def create
    redirect_to root_url && return unless current_user.can_create_patient_vaccines?

    permitted_params = params.require(:vaccine).permit(:vaccinated, :first_vac_date, :second_vac_date, :patient_id)
    
    vac = Vaccine.new(permitted_params)
    vac.save!
    
    History.vac_record(patient: permitted_params[:patient_id],
                       created_by: current_user.email,
                       comment: "User added a new vaccine record (ID: #{vac.id}).")
  end

  def update
    redirect_to root_url && return unless current_user.can_edit_patient_vaccines?

    permitted_params = params.require(:vaccine).permit(:vaccinated, :first_vac_date, :second_vac_date, :patient_id)
    permitted_id = params.require(:id)
    
    vac = Vaccine.find_by(id: permitted_id)
    vac.update!(permitted_params)

    History.vac_record_edit(patient: permitted_params[:patient_id],
                            created_by: current_user.email,
                            comment: "User edited a vaccine record (ID: #{vac.id}).")
  end

end