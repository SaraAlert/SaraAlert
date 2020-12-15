# frozen_string_literal: true

# VaccinesController: Vaccine records
class VaccinesController < ApplicationController
  before_action :authenticate_user!

  # create a new vaccine record
  def create
    redirect_to root_url && return unless current_user.can_create_patient_vaccines?

    permitted_params = params.permit(:vaccinated, :first_vac_date, :second_vac_date, :patient_id)
    
    vac = Vaccine.new(vaccinated: permitted_params.require(:vaccinated).to_sym,
                      first_vac_date: permitted_params.require(:first_vac_date).to_sym,  
                      second_vac_date: permitted_params.require(:second_vac_date).to_sym)
    vac.patient_id = permitted_params.require(:patient_id).to_sym
    vac.save!
    
    History.vac_record(patient: params.permit(:patient_id)[:patient_id],
                       created_by: current_user.email,
                       comment: "User added a new vaccine record (ID: #{vac.id}).")
  end

  def update
    redirect_to root_url && return unless current_user.can_edit_patient_vaccines?

    permitted_params = params.permit(:vaccinated, :first_vac_date, :second_vac_date, :patient_id)
    
    vac = Vaccine.find_by(id: params.permit(:id)[:id])
    vac.update!(vaccinated: permitted_params.require(:vaccinated).to_sym,
                first_vac_date: permitted_params.require(:first_vac_date).to_sym,  
                second_vac_date: permitted_params.require(:second_vac_date).to_sym)

    History.vac_record_edit(patient: permitted_params.require(:patient_id).to_sym,
                            created_by: current_user.email,
                            comment: "User edited a vaccine record (ID: #{vac.id}).")
  end

end