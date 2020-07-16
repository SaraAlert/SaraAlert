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
    # Validate jurisdiction_id param
    jurisdiction_id = params.require(:jurisdiction_id).to_i
    render status: 400 unless current_user.jurisdiction.subtree_ids.include?(jurisdiction_id)
    jurisdiction = current_user.jurisdiction.subtree.find(jurisdiction_id)

    # Validate scope param
    scope = params.require(:scope).to_sym
    render status: 400 unless %i[all exact].include?(scope)

    # Validate workflow param
    workflow = params.permit(:workflow)[:workflow].to_sym unless params.permit(:workflow)[:workflow].nil?
    render status: 400 if workflow && !%i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = params.permit(:tab)[:tab].to_sym unless params.permit(:tab)[:tab].nil?
    render status: 400 if tab && workflow.nil?
    render status: 400 if workflow == 'exposure' && !%i[all symptomatic non_reporting asymptomatic pui closed transferred_in].include?(tab)
    render status: 400 if workflow == 'isolation' && !%i[all requiring_review non_reporting reporting closed transferred_in].include?(tab)

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
      patients = scope == :all ? jurisdiction.transferred_in_patients : jurisdiction.transferred_in_patients.where(jurisdiction_id: jurisdiction_id)
    end

    render json: { assignedUsers: patients.where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort }
  end

  private

  def authenticate_user_role
    render status: 403 unless current_user.can_create_patient? || current_user.can_edit_patient? || current_user.can_view_public_health_dashboard?
  end
end
