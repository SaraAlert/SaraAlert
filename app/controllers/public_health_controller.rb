# frozen_string_literal: true

# PublicHealthController: handles all epi actions
class PublicHealthController < ApplicationController
  include PatientQueryHelper

  before_action :authenticate_user!
  before_action :authenticate_user_role

  def patients
    begin
      patients = patients_table_data(params, current_user)
    rescue InvalidQueryError => e
      return render json: e, status: :bad_request
    end

    render json: patients
  end

  def patients_count
    # Validate filter and sorting params
    begin
      query = validate_patients_query(params.require(:query))
    rescue StandardError => e
      return render json: e, status: :bad_request
    end

    # Get count of filtered patients
    render json: { count: patients_by_query(current_user, query)&.size }
  end

  # Get patient counts by workflow
  def workflow_counts
    render json: {
      global: current_user.viewable_patients.where(purged: false).size,
      exposure: current_user.viewable_patients.where(isolation: false, purged: false).size,
      isolation: current_user.viewable_patients.where(isolation: true, purged: false).size
    }
  end

  # Get counts for patients under the given workflow and tab
  def tab_counts
    # Validate workflow param
    workflow = params.require(:workflow).to_sym
    return head :bad_request unless %i[global exposure isolation].include?(workflow)

    # Validate tab param
    tab = params.require(:tab).to_sym
    case workflow
    when :global
      return head :bad_request unless %i[all active priority_review non_reporting closed].include?(tab)
    when :exposure
      return head :bad_request unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    when :isolation
      return head :bad_request unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    end

    # Get patients by workflow and tab
    patients = patients_by_linelist(current_user, workflow, tab, current_user.jurisdiction)

    render json: { total: patients.size }
  end

  private

  def authenticate_user_role
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?
  end
end
