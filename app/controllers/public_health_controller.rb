# frozen_string_literal: true

# PublicHealthController: handles all epi actions
class PublicHealthController < ApplicationController
  before_action :authenticate_user!

  def exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    @all_count = current_user.viewable_patients.where(isolation: false).where(purged: false).size
    @i_all_count = current_user.viewable_patients.where(isolation: true).where(purged: false).size
    @symptomatic_count = current_user.viewable_patients.symptomatic.where(isolation: false).size
    @pui_count = current_user.viewable_patients.under_investigation.where(isolation: false).size
    @closed_count = current_user.viewable_patients.monitoring_closed_without_purged.where(isolation: false).size
    @non_reporting_count = current_user.viewable_patients.non_reporting.where(isolation: false).size
    @asymptomatic_count = current_user.viewable_patients.asymptomatic.where(isolation: false).size
    @transferred_in_count = current_user.jurisdiction.transferred_in_patients.where(isolation: false).size
    @transferred_out_count = current_user.jurisdiction.transferred_out_patients.where(isolation: false).size
    @assigned_jurisdictions = Hash[Jurisdiction.order(:path).find(current_user.jurisdiction.subtree_ids).pluck(:id, :path).map { |id, path| [id, path] }]
    @assigned_users = current_user.jurisdiction.all_assigned_users
  end

  def isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    @all_count = current_user.viewable_patients.where(isolation: true).where(purged: false).size
    @e_all_count = current_user.viewable_patients.where(isolation: false).where(purged: false).size
    @requiring_review_count = current_user.viewable_patients.isolation_requiring_review.where(isolation: true).size
    @non_reporting_count = current_user.viewable_patients.isolation_non_reporting.where(isolation: true).size
    @reporting_count = current_user.viewable_patients.isolation_reporting.where(isolation: true).size
    @closed_count = current_user.viewable_patients.monitoring_closed_without_purged.where(isolation: true).size
    @transferred_in_count = current_user.jurisdiction.transferred_in_patients.where(isolation: true).size
    @transferred_out_count = current_user.jurisdiction.transferred_out_patients.where(isolation: true).size
    @assigned_jurisdictions = Hash[Jurisdiction.order(:path).find(current_user.jurisdiction.subtree_ids).pluck(:id, :path).map { |id, path| [id, path] }]
    @assigned_users = current_user.jurisdiction.all_assigned_users
  end

  def patients
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    # Validate workflow param
    workflow = params.permit(:workflow)[:workflow].to_sym
    redirect_to(root_url) && return unless %i[exposure isolation].include?(workflow)

    # Validate type param
    type = params.permit(:type)[:type].to_sym
    if workflow == :exposure
      redirect_to(root_url) && return unless %i[all_patients symptomatic_patients non_reporting_patients asymptomatic_patients pui_patients
                                                closed_patients transferred_in_patients transferred_out_patients].include?(type)
    else
      redirect_to(root_url) && return unless %i[all_patients requiring_review_patients non_reporting_patients reporting_patients
                                                closed_patients transferred_in_patients transferred_out_patients].include?(type)
    end

    # Validate assigned jurisdiction param
    assigned_jurisdiction = params.permit(:assigned_jurisdiction)[:assigned_jurisdiction]
    redirect_to(root_url) && return unless assigned_jurisdiction == 'all' || current_user.jurisdiction.subtree_ids.include?(assigned_jurisdiction.to_i)

    # Validate scope param
    scope = params.permit(:scope)[:scope].to_sym
    redirect_to(root_url) && return unless %i[all immediate].include?(scope)

    # Validate assigned user param
    assigned_user = params.permit(:assigned_user)[:assigned_user]
    redirect_to(root_url) && return unless %w[all none].include?(assigned_user) || assigned_user.to_i.between?(1, 9999)

    # Filter by workflow and type
    if type == :transferred_in_patients
      patients = current_user.jurisdiction.transferred_in_patients.where(isolation: workflow == :isolation)
    elsif type == :transferred_out_patients
      patients = current_user.jurisdiction.transferred_out_patients.where(isolation: workflow == :isolation)
    else
      patients = current_user.viewable_patients

      if workflow == :exposure
        patients = patients.where(isolation: false)
        patients = patients.symptomatic if type == :symptomatic_patients
        patients = patients.non_reporting if type == :non_reporting_patients
        patients = patients.asymptomatic if type == :asymptomatic_patients
        patients = patients.under_investigation if type == :pui_patients
      else
        patients = patients.where(isolation: true)
        patients = patients.isolation_requiring_review if type == :requiring_review_patients
        patients = patients.isolation_non_reporting if type == :non_reporting_patients
        patients = patients.isolation_reporting if type == :reporting_patients
      end

      patients = patients.monitoring_closed_without_purged if type == :closed_patients
    end

    # Filter by assigned jurisdiction
    unless assigned_jurisdiction == 'all'
      jur_id = assigned_jurisdiction.to_i
      patients = scope == :all ? patients.where(jurisdiction_id: Jurisdiction.find(jur_id).subtree_ids) : patients.where(jurisdiction_id: jur_id)
    end

    # Filter by assigned user
    patients = patients.where(assigned_user: assigned_user == 'none' ? nil : assigned_user.to_i) unless assigned_user == 'all'

    render json: filter_sort_paginate(params, patients)
  end

  # Get all individuals whose responder_id = id, these people are "HOH eligible"
  def self_reporting
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    patients = current_user.viewable_patients.where('patients.responder_id = patients.id')
    patients = patients.pluck(:id, :first_name, :last_name, :age, :user_defined_id_statelocal).map do |p|
      { id: p[0], first_name: p[1], last_name: p[2], age: p[3], state_id: p[4] }
    end
    patients = patients.sort_by { |p| p[:last_name] }
    render json: { self_reporting: patients.to_json }
  end

  protected

  def filter_sort_paginate(params, data)
    # Filter on search
    filtered = filter(params, data)

    # Sort on columns
    sorted = sort(params, filtered)

    # Paginate
    paginate(params, sorted)
  end

  def filter(params, data)
    search = params[:search][:value] unless params[:search].nil?
    if search.present?
      data.where('first_name like ?', "#{search}%").or(
        data.where('last_name like ?', "#{search}%").or(
          data.where('user_defined_id_statelocal like ?', "#{search}%").or(
            data.where('user_defined_id_cdc like ?', "#{search}%").or(
              data.where('user_defined_id_nndss like ?', "#{search}%").or(
                data.where('date_of_birth like ?', "#{search}%")
              )
            )
          )
        )
      )
    else
      data
    end
  end

  def sort(params, data)
    return data if params[:order].nil?

    sorted = data
    params[:order].each do |_num, val|
      next if params[:columns].nil? || val.nil? || val['column'].blank? || params[:columns][val['column']].nil?
      next if params[:columns][val['column']][:name].blank?

      direction = val['dir'] == 'asc' ? :asc : :desc
      if params[:columns][val['column']][:name] == 'name' # Name
        sorted = sorted.order(last_name: direction).order(first_name: direction)
      elsif params[:columns][val['column']][:name] == 'jurisdiction' # Jurisdiction
        sorted = sorted.includes(:jurisdiction).order('jurisdictions.name ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'assigned_user' # Assigned User
        sorted = sorted.order('CASE WHEN assigned_user IS NULL THEN 1 ELSE 0 END, assigned_user ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'state_local_id' # State/Local ID
        sorted = sorted.order('CASE WHEN user_defined_id_statelocal IS NULL THEN 1 ELSE 0 END, user_defined_id_statelocal ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'sex' # Sex
        sorted = sorted.order('CASE WHEN sex IS NULL THEN 1 ELSE 0 END, sex ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'dob' # DOB
        sorted = sorted.order('CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END, date_of_birth ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'end_of_monitoring' # End of Monitoring
        sorted = sorted.order('CASE WHEN last_date_of_exposure IS NULL THEN 1 ELSE 0 END, last_date_of_exposure ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'expected_purge_date' # Expected Purge Date
        # Same as end of monitoring
        sorted = sorted.order('CASE WHEN last_date_of_exposure IS NULL THEN 1 ELSE 0 END, last_date_of_exposure ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'risk' # Risk
        sorted = sorted.order_by_risk(val['dir'] == 'asc')
      elsif params[:columns][val['column']][:name] == 'monitoring_plan' # Monitoring Plan
        sorted = sorted.order('CASE WHEN monitoring_plan IS NULL THEN 1 ELSE 0 END, monitoring_plan ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'monitoring_reason' # Reason
        sorted = sorted.order('CASE WHEN monitoring_reason IS NULL THEN 1 ELSE 0 END, monitoring_reason ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'public_health_action' # PHA
        sorted = sorted.order('CASE WHEN public_health_action IS NULL THEN 1 ELSE 0 END, public_health_action ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'latest_report' # Latest Report
        sorted = sorted.left_outer_joins(:assessments).order('assessments.created_at ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'closed_at' # Closed At
        sorted = sorted.order('CASE WHEN closed_at IS NULL THEN 1 ELSE 0 END, closed_at ' + direction.to_s)
      end
    end
    sorted
  end

  def paginate(params, data)
    length = params[:length].to_i
    page = params[:start].to_i.zero? ? 1 : (params[:start].to_i / length) + 1
    draw = params[:draw].to_i
    { data: data.paginate(per_page: length, page: page), draw: draw, recordsTotal: data.size, recordsFiltered: data.size }
  end
end
