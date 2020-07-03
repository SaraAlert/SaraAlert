# frozen_string_literal: true

# JurisdictionsController: handles all subject actions
class JurisdictionsController < ApplicationController
  before_action :authenticate_user!

  # Get jurisdiction ids and paths of viewable jurisdictions
  def jurisdiction_paths
    render status: 403 unless current_user.can_create_patient? || current_user.can_edit_patient? || current_user.can_view_public_health_dashboard?

    render json: { jurisdictionPaths: Hash[current_user.jurisdiction.subtree.pluck(:id, :path).map { |id, path| [id, path] }] }
  end

  # Get list of assigned users unique to jurisdiction
  def assigned_users
    render status: 403 unless current_user.can_create_patient? || current_user.can_edit_patient? || current_user.can_view_public_health_dashboard?

    jurisdiction_id = params.require(:jurisdiction_id).to_i

    render status: 400 unless current_user.jurisdiction.subtree_ids.include?(jurisdiction_id)

    scope = params.permit(:scope)[:scope].to_sym
    render status: 400 unless %i[all immediate].include?(scope)

    assigned_users = scope == :all ? Jurisdiction.find(jurisdiction_id).all_assigned_users : Jurisdiction.find(jurisdiction_id).assigned_users

    render json: { assignedUsers: assigned_users }
  end
end
