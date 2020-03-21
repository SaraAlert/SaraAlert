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
    jurisdiction_analytics = current_user.jurisdiction.analytics
    root_jurisdiction_analytics = current_user.jurisdiction.root.analytics
    patient_count_by_day_array = []
    assessment_result_by_day_array = []
    total_patient_count_by_state_and_day = []
    symptomatic_patient_count_by_state_and_day = []
    dates = (jurisdiction_analytics.pluck(:created_at).min.to_date..jurisdiction_analytics.pluck(:created_at).max.to_date).to_a
    dates.each do |date|
      next if date.nil?

      # Get last saved analytic for each date
      analytic = jurisdiction_analytics.where(created_at: date.beginning_of_day..date.end_of_day).last
      root_analytic = root_jurisdiction_analytics.where(created_at: date.beginning_of_day..date.end_of_day).last
      open_cases = !analytic&.open_cases_count.nil? ? analytic.open_cases_count : 0
      patient_count_by_day_array << { day: date, cases: open_cases }
      symp_count = !analytic&.symptomatic_monitorees_count.nil? ? analytic.symptomatic_monitorees_count : 0
      asymp_count = !analytic&.asymptomatic_monitorees_count.nil? ? analytic.asymptomatic_monitorees_count : 0
      assessment_result_by_day_array << {
        'name' => date.to_s,
        'Symptomatic Assessments' => symp_count,
        'Asymptomatic Assessments' => asymp_count
      }
      # Map analytics are pulled from the root (most likely USA) jurisdiction
      sym_map = !root_analytic&.monitoree_state_map.nil? ? (JSON.parse root_analytic.monitoree_state_map.gsub('=>', ':').gsub('nil', '"Unknown"')) : {}
      symptomatic_patient_count_by_state_and_day << { day: date }.merge(sym_map)
      count_map = !root_analytic&.symptomatic_state_map.nil? ? (JSON.parse root_analytic.symptomatic_state_map.gsub('=>', ':').gsub('nil', '"Unknown"')) : {}
      total_patient_count_by_state_and_day << { day: date }.merge(count_map)
    end

    most_recent_analytics = current_user.jurisdiction.analytics.last

    {
      last_updated_at: most_recent_analytics.updated_at,
      subject_status: [
        { name: 'Asymptomatic', value: most_recent_analytics.asymptomatic_monitorees_count },
        { name: 'Non-Reporting', value: most_recent_analytics.non_reporting_monitorees_count },
        { name: 'Symptomatic', value: most_recent_analytics.symptomatic_monitorees_count },
        { name: 'Closed', value: most_recent_analytics.closed_cases_count }
      ],
      reporting_summmary: [
        { name: 'Reported Today', value: most_recent_analytics.open_cases_count - most_recent_analytics.non_reporting_monitorees_count },
        { name: 'Not Yet Reported', value: most_recent_analytics.non_reporting_monitorees_count }
      ],
      monitoring_distribution_by_day: patient_count_by_day_array,
      symptomatic_patient_count_by_state_and_day: symptomatic_patient_count_by_state_and_day,
      total_patient_count_by_state_and_day: total_patient_count_by_state_and_day,
      assessment_result_by_day: assessment_result_by_day_array
    }
  end
end
