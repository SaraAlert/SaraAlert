# frozen_string_literal: true

# VaccinesController: Vaccine records
class VaccinesController < ApplicationController
  before_action :authenticate_user!

  # create a new vaccine record
  def create
    redirect_to root_url && return unless current_user.can_create_patient_vaccines?
    
    vac = Vaccine.new(vaccinated: params.permit(:vaccinated)[:vaccinated],
                      first_vac_date: params.permit(:first_vac_date)[:first_vac_date],  
                      second_vac_date: params.permit(:second_vac_date)[:second_vac_date])
    vac.patient_id = params.permit(:patient_id)[:patient_id]
    vac.save!
    History.vac_record(patient: params.permit(:patient_id)[:patient_id],
                       created_by: current_user.email,
                       comment: "User added a new vaccine record (ID: #{vac.id}).")
  end

  def update
    redirect_to root_url && return unless current_user.can_edit_patient_vaccines?
    
    vac = Vaccine.find_by(id: params.permit(:id)[:id])
    vac.update!(vaccinated: params.permit(:vaccinated)[:vaccinated],
                first_vac_date: params.permit(:first_vac_date)[:first_vac_date],  
                second_vac_date: params.permit(:second_vac_date)[:second_vac_date])
    History.vac_record_edit(patient: params.permit(:patient_id)[:patient_id],
                            created_by: current_user.email,
                            comment: "User edited a vaccine record (ID: #{vac.id}).")
  end

end