# frozen_string_literal: true

# JurisdictionsController: handles all subject actions
class JurisdictionsController < ApplicationController
  include PatientQueryHelper

  before_action :authenticate_user!
  before_action :authenticate_user_role

  # Get jurisdiction ids and paths of viewable jurisdictions
  def jurisdiction_paths
    render json: { jurisdiction_paths: Hash[current_user.jurisdiction.subtree.pluck(:id, :path).map { |id, path| [id, path] }] }
  end

  # Get all jurisdiction ids and paths
  def all_jurisdiction_paths
    render json: { all_jurisdiction_paths: Hash[Jurisdiction.all.pluck(:id, :path).map { |id, path| [id, path] }] }
  end

  # Get list of assigned users unique to jurisdiction
  def assigned_users_for_viewable_patients
    # Require jurisdiction and scope params
    params.require(:query).require(:jurisdiction)
    params.require(:query).require(:scope)

    # Validate filter and sorting params
    begin
      query = validate_patients_query(params.require(:query))
    rescue StandardError => e
      return render json: e, status: :bad_request
    end

    # Get distinct assigned users from filtered patients
    render json: { assigned_users: patients_by_query(current_user, query).where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort }
  end

  private

  def authenticate_user_role
    return head :unauthorized unless current_user.can_create_patient? || current_user.can_edit_patient? ||
                                     current_user.can_view_public_health_dashboard? || current_user.admin?
  end
end
