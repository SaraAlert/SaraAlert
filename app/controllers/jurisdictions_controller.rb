# frozen_string_literal: true

# JurisdictionsController: handles all subject actions
class JurisdictionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_user_role

  # Get jurisdiction ids and paths of viewable jurisdictions
  def jurisdiction_paths
    render json: { jurisdictionPaths: Hash[current_user.jurisdiction.subtree.pluck(:id, :path).map { |id, path| [id, path] }] }
  end

  # Get list of assigned users unique to jurisdiction
  def assigned_users_for_viewable_patients
    permitted_params = params.permit(:jurisdiction_id, :scope, :workflow, :tab)

    # Validate jurisdiction_id param
    jurisdiction_id = permitted_params.require(:jurisdiction_id).to_i
    return head :bad_request unless current_user.jurisdiction.subtree_ids.include?(jurisdiction_id)

    jurisdiction = current_user.jurisdiction.subtree.find(jurisdiction_id)

    # Validate scope param
    scope = permitted_params.require(:scope).to_sym
    return head :bad_request unless %i[all exact].include?(scope)

    # Validate workflow param
    workflow = permitted_params[:workflow].to_sym unless permitted_params[:workflow].nil?
    return head :bad_request unless workflow.nil? || %i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = permitted_params[:tab].to_sym unless params.permit(:tab)[:tab].nil?
    return head :bad_request if tab && workflow.nil? ||
                                workflow == :exposure && !%i[all symptomatic non_reporting asymptomatic pui closed transferred_in].include?(tab) ||
                                workflow == :isolation && !%i[all requiring_review non_reporting reporting closed transferred_in].include?(tab)

    # Start by getting all or immediate patients from jurisdiction
    patients = scope == :all ? jurisdiction.all_patients : jurisdiction.immediate_patients

    # Filter by workflow and tab
    if workflow == :exposure
      patients = patients.where(isolation: false, purged: false)
      patients = patients.exposure_symptomatic if tab == :symptomatic
      patients = patients.exposure_non_reporting if tab == :non_reporting
      patients = patients.exposure_asymptomatic if tab == :asymptomatic
      patients = patients.exposure_under_investigation if tab == :pui
    end

    if workflow == :isolation
      patients = patients.where(isolation: true, purged: false)
      patients = patients.isolation_requiring_review if tab == :requiring_review
      patients = patients.isolation_non_reporting if tab == :non_reporting
      patients = patients.isolation_reporting if tab == :reporting
    end

    patients = patients.monitoring_closed_without_purged if tab == :closed

    if tab == :transferred_in
      patients = jurisdiction.transferred_in_patients.where(isolation: workflow == :isolation)
      patients = patients.where(jurisdiction_id: jurisdiction_id) if scope == :exact
    end

    render json: { assignedUsers: patients.where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort }
  end

  private

  def authenticate_user_role
    return head :unauthorized unless current_user.can_create_patient? || current_user.can_edit_patient? || current_user.can_view_public_health_dashboard?
  end
end
