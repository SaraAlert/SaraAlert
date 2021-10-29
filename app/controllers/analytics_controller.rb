# frozen_string_literal: true

# AnalyticsController: for analytics actions
class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Restrict access to analytics users only
    redirect_to(root_url) && return unless current_user.can_view_analytics?

    @title = 'Analytics'

    # Stats for enrollers
    @stats = enroller_stats if current_user.role?(Roles::ENROLLER)

    # Stats for public health & analysts (store @can_view_epi_analytics in class variable to prevent duplicate query from view)
    @can_view_epi_analytics = current_user.can_view_epi_analytics?
    @stats = epi_stats if @can_view_epi_analytics

    redirect_to(root_url) && return if @stats.nil?
  end

  def clm_geo_json
    all_map_files = %w[al ak az ar ca co ct de dc fl ga hi id il in ia ks ky la
                       me md ma mi mn ms mo mt ne nv nh nj nm ny nc nd oh ok or
                       pa ri sc sd tn tx usaTerritories ut vt va wa wv wi wy]
    map_file_name = params[:mapFile].to_s

    return unless all_map_files.include? map_file_name

    send_file(Rails.root.join('public', 'CountyLevelMaps', "#{map_file_name}.json"), filename: "#{map_file_name}.json", type: 'application/json')
  end

  def monitoree_maps
    # Restrict access to public health & analysts users only
    redirect_to(root_url) && return unless current_user.can_view_analytics?

    # Only query user jurisdiction once
    jur = current_user.jurisdiction

    # Query analytic ids and dates of latest analytics of each of the last 10 days (ordering by created_at then calling to_h will guarantee 1 analytic per day)
    recent_analytics = jur.analytics.where('created_at > ?', 10.days.ago.to_date).order(:created_at).pluck('DATE(created_at)', :id).to_h.invert

    # Query monitoree maps of those analytics
    maps = MonitoreeMap.where(analytic_id: recent_analytics.keys)
    maps = maps.where(level: 'State') unless jur.root?

    render json: { monitoree_maps: maps.group_by(&:analytic_id).map { |id, m| { day: recent_analytics[id], maps: m } } }
  end

  protected

  # Time.zone is set by Rails.application.config.time_zone which defaults to UTC.
  # Therefore, Time.zone.today makes UTC explicit and is consistient with previous behavior.
  def enroller_stats
    {
      system_subjects: Patient.count,
      system_subjects_last_24: Patient.where('created_at >= ?', Time.zone.now - 1.day).count,
      system_assessments: Assessment.count,
      system_assessments_last_24: Assessment.where('created_at >= ?', Time.zone.now - 1.day).count,
      user_subjects: Patient.where(creator_id: current_user.id).count,
      user_subjects_last_24: Patient.where(creator_id: current_user.id).where('created_at >= ?', Time.zone.now - 1.day).count,
      user_assessments: Patient.where(creator_id: current_user.id).joins(:assessments).count,
      user_assessments_last_24: Patient.where(creator_id: current_user.id).joins(:assessments).where('assessments.created_at >= ?', Time.zone.now - 1.day).count
    }
  end

  def epi_stats
    # Get analytics from most recent cache analytics job
    most_recent_analytics = current_user.jurisdiction.analytics.last
    return {} if most_recent_analytics.nil?

    {
      last_updated_at: most_recent_analytics.updated_at,
      monitoree_counts: most_recent_analytics.monitoree_counts,
      monitoree_snapshots: most_recent_analytics.monitoree_snapshots
    }
  end
end
