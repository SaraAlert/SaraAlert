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

  def get_jurisdiction_data
    # STUB ENDPOINT
    # Currently just returns massachusetts values
    render json:
    {
      "total": {
        "Worcester": 12,
        "Suffolk": 145,
        "Plymouth": 14,
        "Norfolk": 68,
        "Nantucket": 12,
        "Middlesex": 75,
        "Hampshire": 13,
        "Hampden": 11,
        "Franklin": 9,
        "Essex": 86,
        "Dukes": 7,
        "Bristol": 10,
        "Berkshire": 1,
        "Barnstable": 25
      },
      "symptomatic": {
        "Worcester": 14,
        "Suffolk": 98,
        "Plymouth": 16,
        "Norfolk": 25,
        "Nantucket": 15,
        "Middlesex": 56,
        "Hampshire": 13,
        "Hampden": 23,
        "Franklin": 13,
        "Essex": 87,
        "Dukes": 23,
        "Bristol": 12,
        "Berkshire": 1,
        "Barnstable": 12
    }
  }
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
    # Map analytics are pulled from the root jurisdiction (will be removed and replaced by new monitoree_maps data when ready)
    root_jurisdiction_analytics = current_user.jurisdiction.root.analytics
    total_patient_count_by_state_and_day = []
    symptomatic_patient_count_by_state_and_day = []
    dates = (14.days.ago.to_date..Date.today).to_a
    dates.each do |date|
      next if date.nil?

      # Get last saved analytic for each date
      root_analytic = root_jurisdiction_analytics.where(created_at: date.beginning_of_day..date.end_of_day).last
      sym_map = !root_analytic&.monitoree_state_map.nil? ? (JSON.parse root_analytic.monitoree_state_map.gsub('=>', ':').gsub('nil', '"Unknown"')) : {}
      symptomatic_patient_count_by_state_and_day << { day: date }.merge(sym_map)
      count_map = !root_analytic&.symptomatic_state_map.nil? ? (JSON.parse root_analytic.symptomatic_state_map.gsub('=>', ':').gsub('nil', '"Unknown"')) : {}
      total_patient_count_by_state_and_day << { day: date }.merge(count_map)
    end

    # Get analytics from most recent cache analytics job
    most_recent_analytics = current_user.jurisdiction.analytics.last

    return nil if most_recent_analytics.nil?

    {
      last_updated_at: most_recent_analytics.updated_at,
      symptomatic_patient_count_by_state_and_day: symptomatic_patient_count_by_state_and_day,
      total_patient_count_by_state_and_day: total_patient_count_by_state_and_day,
      monitoree_counts: MonitoreeCount.where(analytic_id: most_recent_analytics.id),
      monitoree_snapshots: MonitoreeSnapshot.where(analytic_id: most_recent_analytics.id)
    }
  end
end
