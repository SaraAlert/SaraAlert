# frozen_string_literal: true

# PublicHealthController: handles all epi actions
class PublicHealthController < ApplicationController
  before_action :authenticate_user!

  def index
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?
    @symptomatic_count = current_user.viewable_patients.symptomatic.count
    @closed_count = current_user.viewable_patients.monitoring_closed_without_purged.count
    @non_reporting_count = current_user.viewable_patients.non_reporting.count
    @asymptomatic_count = current_user.viewable_patients.asymptomatic.count
    @transferred_in_count = current_user.jurisdiction.transferred_in_patients.count
    @transferred_out_count = current_user.jurisdiction.transferred_out_patients.count
  end

  def symptomatic_patients
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients.symptomatic)
  end

  def closed_patients
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients.monitoring_closed_without_purged)
  end

  def non_reporting_patients
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients.non_reporting)
  end

  def asymptomatic_patients
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.viewable_patients.asymptomatic)
  end

  def transferred_in_patients
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.jurisdiction.transferred_in_patients)
  end

  def transferred_out_patients
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: filter_sort_paginate(params, current_user.jurisdiction.transferred_out_patients)
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
      data.where('lower(first_name) like ?', "%#{search.downcase}%").or(
        data.where('lower(last_name) like ?', "%#{search.downcase}%").or(
          data.where('lower(user_defined_id_statelocal) like ?', "%#{search.downcase}%")
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
      direction = val['dir'] == 'asc' ? :asc : :desc
      if val['column'] == '0' # Name
        sorted = sorted.order(last_name: direction).order(first_name: direction)
      elsif val['column'] == '1' # Jurisdiction
        sorted = sorted.includes(:jurisdiction).order('jurisdictions.name ' + direction.to_s)
      elsif val['column'] == '2' # ID
        sorted = sorted.order(user_defined_id_statelocal: direction)
      elsif val['column'] == '3' # Sex
        sorted = sorted.order(sex: direction)
      elsif val['column'] == '4' # DOB
        sorted = sorted.order(date_of_birth: direction)
      elsif val['column'] == '5' # End of Monitoring
        sorted = sorted.order(last_date_of_exposure: direction)
      elsif val['column'] == '6' # Risk
        sorted = sorted.order_by_risk(val['dir'] == 'asc')
      elsif val['column'] == '7' # Plan
        sorted = sorted.order(monitoring_plan: direction)
      elsif val['column'] == '8' # Latest Report
        sorted = sorted.includes(:latest_assessment).order('assessments.created_at ' + direction.to_s)
      end
    end
    sorted
  end

  def paginate(params, data)
    length = params[:length].to_i
    page = params[:start].to_i.zero? ? 1 : (params[:start].to_i / length) + 1
    draw = params[:draw].to_i
    { data: data.paginate(per_page: length, page: page), draw: draw, recordsTotal: data.count, recordsFiltered: data.count }
  end
end
