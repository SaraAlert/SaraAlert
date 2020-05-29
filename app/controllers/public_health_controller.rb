# frozen_string_literal: true

# PublicHealthController: handles all epi actions
class PublicHealthController < ApplicationController
  before_action :authenticate_user!

  #############################################################################
  # EXPOSURE
  #############################################################################

  def exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    @all_count = current_user.viewable_patients.where(isolation: false).size
    @i_all_count = current_user.viewable_patients.where(isolation: true).size
    @symptomatic_count = current_user.viewable_patients.symptomatic.where(isolation: false).size
    @pui_count = current_user.viewable_patients.under_investigation.where(isolation: false).size
    @closed_count = current_user.viewable_patients.monitoring_closed_without_purged.where(isolation: false).size
    @non_reporting_count = current_user.viewable_patients.non_reporting.where(isolation: false).size
    @asymptomatic_count = current_user.viewable_patients.asymptomatic.where(isolation: false).size
    @transferred_in_count = current_user.jurisdiction.transferred_in_patients.where(isolation: false).size
    @transferred_out_count = current_user.jurisdiction.transferred_out_patients.where(isolation: false).size
    @jurisdictions = Hash[Jurisdiction.order(:path).find(current_user.jurisdiction.subtree_ids).pluck(:path, :id).map {|path, id| [path, id]}]
    @groups = current_user.jurisdiction.assigned_users
  end

  def all_patients_exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .where(isolation: false))
  end

  def symptomatic_patients_exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .symptomatic
                                                          .where(isolation: false))
  end

  def pui_patients_exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .under_investigation
                                                          .where(isolation: false))
  end

  def closed_patients_exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .monitoring_closed_without_purged
                                                          .where(isolation: false))
  end

  def non_reporting_patients_exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .non_reporting
                                                          .where(isolation: false))
  end

  def asymptomatic_patients_exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .asymptomatic
                                                          .where(isolation: false))
  end

  def transferred_in_patients_exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.jurisdiction
                                                          .transferred_in_patients
                                                          .where(isolation: false))
  end

  def transferred_out_patients_exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.jurisdiction.transferred_out_patients
                                                                       .where(isolation: false))
  end

  #############################################################################
  # ISOLATION
  #############################################################################

  def isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    @all_count = current_user.viewable_patients.where(isolation: true).size
    @e_all_count = current_user.viewable_patients.where(isolation: false).size
    @requiring_review_count = current_user.viewable_patients.isolation_requiring_review.where(isolation: true).size
    @non_reporting_count = current_user.viewable_patients.isolation_non_reporting.where(isolation: true).size
    @reporting_count = current_user.viewable_patients.isolation_reporting.where(isolation: true).size
    @closed_count = current_user.viewable_patients.monitoring_closed_without_purged.where(isolation: true).size
    @transferred_in_count = current_user.jurisdiction.transferred_in_patients.where(isolation: true).size
    @transferred_out_count = current_user.jurisdiction.transferred_out_patients.where(isolation: true).size
    @jurisdictions = Hash[Jurisdiction.order(:path).find(current_user.jurisdiction.subtree_ids).pluck(:path, :id).map {|path, id| [path, id]}]
    @groups = current_user.jurisdiction.assigned_users
  end

  def all_patients_isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .where(isolation: true))
  end

  def requiring_review_patients_isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .isolation_requiring_review
                                                          .where(isolation: true))
  end

  def closed_patients_isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .monitoring_closed_without_purged
                                                          .where(isolation: true))
  end

  def non_reporting_patients_isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .isolation_non_reporting
                                                          .where(isolation: true))
  end

  def reporting_patients_isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients
                                                          .isolation_reporting
                                                          .where(isolation: true))
  end

  def transferred_in_patients_isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.jurisdiction.transferred_in_patients
                                                                       .where(isolation: true))
  end

  def transferred_out_patients_isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.jurisdiction.transferred_out_patients
                                                                       .where(isolation: true))
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
      elsif params[:columns][val['column']][:name] == 'state_local_id' # ID
        sorted = sorted.order(user_defined_id_statelocal: direction)
      elsif params[:columns][val['column']][:name] == 'sex' # Sex
        sorted = sorted.order(sex: direction)
      elsif params[:columns][val['column']][:name] == 'dob' # DOB
        sorted = sorted.order(date_of_birth: direction)
      elsif params[:columns][val['column']][:name] == 'end_of_monitoring' # End of Monitoring
        sorted = sorted.order(last_date_of_exposure: direction)
      elsif params[:columns][val['column']][:name] == 'expected_purge_date' # Expected Purge Date
        # Same as end of monitoring
        sorted = sorted.order(last_date_of_exposure: direction)
      elsif params[:columns][val['column']][:name] == 'risk' # Risk
        sorted = sorted.order_by_risk(val['dir'] == 'asc')
      elsif params[:columns][val['column']][:name] == 'monitoring_plan' # Plan
        sorted = sorted.order(monitoring_plan: direction)
      elsif params[:columns][val['column']][:name] == 'monitoring_reason' # Reason
        sorted = sorted.order(monitoring_reason: direction)
      elsif params[:columns][val['column']][:name] == 'public_health_action' # PHA
        sorted = sorted.order(public_health_action: direction)
      elsif params[:columns][val['column']][:name] == 'latest_report' # Latest Report
        sorted = sorted.includes(:assessments).order('assessments.created_at ' + direction.to_s)
      elsif params[:columns][val['column']][:name] == 'closed_at' # Closed At
        sorted = sorted.order(closed_at: direction)
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
