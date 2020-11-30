# frozen_string_literal: true

# UserExportPresetsController: used to manage user saved export presets
class UserExportPresetsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_role

  def index
    render json: current_user.user_export_presets.collect { |preset| { config: JSON.parse(preset.config), name: preset.name, id: preset.id } }
  end

  def create
    return head :bad_request unless current_user.user_export_presets.count < 100 # Enforce upper limit per user

    config = params.require(:config).permit(:filename, :format, data: {})

    saved_export_preset = UserExportPreset.create!(user_id: current_user.id, name: params.require(:name), config: config.to_json)
    saved_export_preset[:config] = JSON.parse(saved_export_preset[:config])
    render json: saved_export_preset
  end

  def update
    saved_export_preset = current_user.user_export_presets.find(params.require(:id))
    return head :bad_request if saved_export_preset.nil?

    config = params.require(:config).permit(:filename, :format, data: {})

    saved_export_preset.update(name: params.require(:name), config: config.to_json)
    saved_export_preset[:config] = JSON.parse(saved_export_preset[:config])
    render json: saved_export_preset
  end

  def destroy
    current_user.user_export_presets.find(params.require(:id)).destroy!
  end

  private

  def check_role
    current_user.can_manage_saved_export_presets?
  end
end
