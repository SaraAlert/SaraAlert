# frozen_string_literal: true

# AnalyticsController: for analytics actions
class AnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Restrict access to analytics users only
    redirect_to(root_url) && return unless current_user.can_view_analytics?

    # Stats for enrollers
    @stats = enroller_stats if current_user.has_role?(:enroller)

    # Stats for public health & analysts
    @stats = epi_stats if current_user.has_role?(:public_health) || current_user.has_role?(:public_health_enroller) || current_user.has_role?(:analyst)

    redirect_to(root_url) && return if @stats.nil?
  end

  def get_geo_json
    send_file(
      "#{Rails.root}/public/CountyLevelMaps/#{params[:mapFile]}.json",
      filename: "#{params[:mapFile]}.json",
      type: 'application/json'
    )
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

      if current_user.jurisdiction.root?
        maps << { day: date, maps: MonitoreeMap.where(analytic_id: analytic.id, level: 'State') }
      else
        maps << { day: date, maps: MonitoreeMap.where(analytic_id: analytic.id) }
      end
    end

    # Get analytics from most recent cache analytics job
    most_recent_analytics = current_user.jurisdiction.analytics.last

    return nil if most_recent_analytics.nil?

    {
      last_updated_at: most_recent_analytics.updated_at,
      monitoree_counts: MonitoreeCount.where(analytic_id: most_recent_analytics.id),
      monitoree_snapshots: MonitoreeSnapshot.where(analytic_id: most_recent_analytics.id),
      monitoree_maps: maps
    }
  end
end
