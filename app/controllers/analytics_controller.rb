# frozen_string_literal: true

# AnalyticsController: for analytics actions
class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Restrict access to analytics users only
    redirect_to(root_url) && return unless current_user.can_view_analytics?

    # Stats for enrollers
    @stats = enroller_stats if current_user.role?(Roles::ENROLLER)

    # Stats for public health & analysts
    @stats = epi_stats if current_user.can_view_epi_analytics?

    redirect_to(root_url) && return if @stats.nil?
  end

  def clm_geo_json
    all_map_files = %w[al ak az ar ca co ct de dc fl ga hi id il in ia ks ky la
                       me md ma mi mn ms mo mt ne nv nh nj nm ny nc nd oh ok or
                       pa ri sc sd tn tx usaTerritories ut vt va wa wv wi wy]
    map_file_name = params[:mapFile].to_s

    return unless all_map_files.include? map_file_name

    send_file("#{Rails.root}/public/CountyLevelMaps/#{map_file_name}.json", filename: "#{map_file_name}.json", type: 'application/json')
  end

  protected

  def enroller_stats
    {
      system_subjects: Patient.count,
      system_subjects_last_24: Patient.where('created_at >= ?', Time.now - 1.day).count,
      system_assessments: Assessment.count,
      system_assessments_last_24: Assessment.where('created_at >= ?', Time.now - 1.day).count,
      user_subjects: Patient.where(creator_id: current_user.id).count,
      user_subjects_last_24: Patient.where(creator_id: current_user.id).where('created_at >= ?', Time.now - 1.day).count,
      user_assessments: Patient.where(creator_id: current_user.id).joins(:assessments).count,
      user_assessments_last_24: Patient.where(creator_id: current_user.id).joins(:assessments).where('assessments.created_at >= ?', Time.now - 1.day).count
    }
  end

  def epi_stats
    analytics = current_user.jurisdiction.analytics

    # Retrieve map analytics from up to 14 days ago
    maps = []
    dates = (14.days.ago.to_date..Date.today).to_a
    dates.each do |date|
      next if date.nil?

      # Get last saved analytic for each date
      analytic = analytics.where(created_at: date.beginning_of_day..date.end_of_day).last

      next if analytic.nil?

      maps << if current_user.jurisdiction.root?
                { day: date, maps: MonitoreeMap.where(analytic_id: analytic.id, level: 'State') }
              else
                { day: date, maps: MonitoreeMap.where(analytic_id: analytic.id) }
              end
    end

    # Get analytics from most recent cache analytics job
    most_recent_analytics = current_user.jurisdiction.analytics.last

    return {} if most_recent_analytics.nil?

    {
      last_updated_at: most_recent_analytics.updated_at,
      monitoree_counts: MonitoreeCount.where(analytic_id: most_recent_analytics.id),
      monitoree_snapshots: MonitoreeSnapshot.where(analytic_id: most_recent_analytics.id),
      monitoree_maps: maps
    }
  end
end
