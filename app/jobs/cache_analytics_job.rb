# frozen_string_literal: true

# CacheAnalyticsJob: caches the latest available analytics
class CacheAnalyticsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    cached = []
    not_cached = []

    Jurisdiction.find_each do |jur|
      Analytic.transaction do
        analytic = Analytic.create!(jurisdiction_id: jur.id)
        patients = jur.all_patients
        MonitoreeCount.import! self.class.all_monitoree_counts(analytic.id, patients)
        MonitoreeSnapshot.import! self.class.all_monitoree_snapshots(analytic.id, patients, jur.id)
        MonitoreeMap.import! self.class.state_level_maps(analytic.id, patients)
        MonitoreeMap.import! self.class.county_level_maps(analytic.id, patients) unless jur.root?
      end
      cached << { id: jur.id, name: jur.jurisdiction_path_string }
    rescue StandardError => e
      not_cached << { id: jur.id, name: jur.jurisdiction_path_string, reason: e.message }
      next
    end

    # Send results
    UserMailer.cache_analytics_job_email(cached, not_cached, Jurisdiction.count).deliver_now
  end

  MONITORING_STATUSES ||= %w[Symptomatic Non-Reporting Asymptomatic].freeze
  LINELIST_STATUSES = ['Exposure Symptomatic','Exposure Non-Reporting','Exposure Asymptomatic','Exposure PUI','Isolation Requiring Review','Isolation Non-Reporting','Isolation Reporting'].freeze
  RISK_FACTORS ||= {
    contact_of_known_case: 'Close Contact with Known Case',
    travel_to_affected_country_or_area: 'Travel from Affected Country or Area',
    was_in_health_care_facility_with_known_cases: 'Was in Healthcare Facility with Known Cases',
    healthcare_personnel: 'Healthcare Personnel',
    member_of_a_common_exposure_cohort: 'Common Exposure Cohort',
    crew_on_passenger_or_cargo_flight: 'Crew on Passenger or Cargo Flight',
    laboratory_personnel: 'Laboratory Personnel'
  }.freeze
  MONITOREE_SNAPSHOT_TIME_FRAMES ||= ['Last 24 Hours', 'Last 14 Days', 'Total'].freeze
  NUM_EXPOSURE_COUNTRIES ||= 5
  NUM_PAST_EXPOSURE_DAYS ||= 28
  NUM_PAST_EXPOSURE_WEEKS ||= 53
  NUM_PAST_EXPOSURE_MONTHS ||= 13

  # Compute all monitoree counts
  def self.all_monitoree_counts(analytic_id, monitorees)
    counts = []

    # Active and overall total counts
    counts.concat(monitoree_counts_by_total(analytic_id, monitorees, true))
    counts.concat(monitoree_counts_by_total(analytic_id, monitorees, false))

    # Monitoring status counts for today's reporting summary
    counts.concat(monitoree_counts_by_monitoring_status(analytic_id, monitorees))

    # Active and overall counts for epidemiological summary
    counts.concat(monitoree_counts_by_age_group(analytic_id, monitorees, true))
    counts.concat(monitoree_counts_by_age_group(analytic_id, monitorees, false))
    counts.concat(monitoree_counts_by_sex(analytic_id, monitorees, true))
    counts.concat(monitoree_counts_by_sex(analytic_id, monitorees, false))
    counts.concat(monitoree_counts_by_reporting_method(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_risk_factor(analytic_id, monitorees, true))
    counts.concat(monitoree_counts_by_risk_factor(analytic_id, monitorees, false))
    counts.concat(monitoree_counts_by_exposure_country(analytic_id, monitorees, true))
    counts.concat(monitoree_counts_by_exposure_country(analytic_id, monitorees, false))

    # Active and overall counts for date of last exposure
    counts.concat(monitoree_counts_by_last_exposure_date(analytic_id, monitorees, true))
    counts.concat(monitoree_counts_by_last_exposure_date(analytic_id, monitorees, false))
    counts.concat(monitoree_counts_by_last_exposure_week(analytic_id, monitorees, true))
    counts.concat(monitoree_counts_by_last_exposure_week(analytic_id, monitorees, false))
    counts.concat(monitoree_counts_by_last_exposure_month(analytic_id, monitorees, true))
    counts.concat(monitoree_counts_by_last_exposure_month(analytic_id, monitorees, false))

    counts
  end

  # Total monitoree counts
  def self.monitoree_counts_by_total(analytic_id, monitorees, active_monitoring)
    monitorees.monitoring_active(active_monitoring)
              .group(:exposure_risk_assessment)
              .order(:exposure_risk_assessment)
              .size
              .map do |risk_level, total|
                monitoree_count(analytic_id, active_monitoring, 'Overall Total', 'Total', risk_level, total)
              end
  end

  # Monitoree counts by monitoring status (symptomatic, non-reporting, asymptomatic)
  def self.monitoree_counts_by_monitoring_status(analytic_id, monitorees)
    counts = []
    MONITORING_STATUSES.each do |monitoring_status|
      monitorees.monitoring_status(monitoring_status)
                .group(:exposure_risk_assessment)
                .order(:exposure_risk_assessment)
                .size
                .each do |risk_level, total|
                  counts.append(monitoree_count(analytic_id, true, 'Monitoring Status', monitoring_status, risk_level, total))
                end
    end
    counts
  end

  # Monitoree counts by age group
  def self.monitoree_counts_by_age_group(analytic_id, monitorees, active_monitoring)
    age_groups = <<-SQL
      CASE
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 20 THEN '0-19'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 20 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 30 THEN '20-29'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 30 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 40 THEN '30-39'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 40 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 50 THEN '40-49'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 50 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 60 THEN '50-59'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 60 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 70 THEN '60-69'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 70 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 80 THEN '70-79'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 80 THEN '>=80'
      END
    SQL
    monitorees.monitoring_active(active_monitoring)
              .group(age_groups, :exposure_risk_assessment)
              .order(Arel.sql(age_groups), :exposure_risk_assessment)
              .size
              .map do |(age_group, risk), total|
                monitoree_count(analytic_id, active_monitoring, 'Age Group', age_group, risk, total)
              end
  end

  # Monitoree counts by sex
  def self.monitoree_counts_by_sex(analytic_id, monitorees, active_monitoring)
    monitorees.monitoring_active(active_monitoring)
              .group(:sex, :exposure_risk_assessment)
              .order(:sex, :exposure_risk_assessment)
              .size
              .map do |(sex, risk), total|
                monitoree_count(analytic_id, active_monitoring, 'Sex', sex.nil? ? 'Missing' : sex, risk, total)
              end
  end

# Monitoree counts by monitoring status (symptomatic, non-reporting, asymptomatic)
  def self.monitoree_counts_by_reporting_method(analytic_id, monitorees)
    counts = []
    LINELIST_STATUSES.each do |linelist_status|
      monitorees.monitoring_status(linelist_status)
                .group(:preferred_contact_method)
                .order(:preferred_contact_method)
                .size
                .map do |preferred_contact_method, total|
                  counts.append(monitoree_count(analytic_id, true, 'Contact Method', preferred_contact_method.nil? ? 'Missing' : preferred_contact_method, nil, total, linelist_status))
                end
    end
  end

  # Monitoree counts by exposure risk factors
  def self.monitoree_counts_by_risk_factor(analytic_id, monitorees, active_monitoring)
    counts = []
    # Individual risk factors
    RISK_FACTORS.each do |risk_factor, label|
      monitorees.monitoring_active(active_monitoring)
                .where(risk_factor => true)
                .group(risk_factor, :exposure_risk_assessment)
                .order(:exposure_risk_assessment)
                .size
                .map do |(_, risk), total|
                  counts.append(monitoree_count(analytic_id, active_monitoring, 'Risk Factor', label, risk, total))
                end
    end
    # Total
    monitorees.monitoring_active(active_monitoring)
              .where(RISK_FACTORS.keys.join(' OR '))
              .group(:exposure_risk_assessment)
              .order(:exposure_risk_assessment)
              .size
              .map do |risk_level, total|
                counts.append(monitoree_count(analytic_id, active_monitoring, 'Risk Factor', 'Total', risk_level, total))
              end
    counts
  end

  # Monitoree counts by exposure country
  def self.monitoree_counts_by_exposure_country(analytic_id, monitorees, active_monitoring)
    counts = []
    # Individual countries
    exposure_countries = monitorees.monitoring_active(active_monitoring)
                                   .where.not(potential_exposure_country: nil)
                                   .group(:potential_exposure_country)
                                   .order(count_potential_exposure_country: :desc)
                                   .order(:potential_exposure_country)
                                   .limit(NUM_EXPOSURE_COUNTRIES)
                                   .count(:potential_exposure_country)
                                   .map { |c| c[0] }
    monitorees.monitoring_active(active_monitoring)
              .where(potential_exposure_country: exposure_countries)
              .group(:potential_exposure_country, :exposure_risk_assessment)
              .order(:potential_exposure_country, :exposure_risk_assessment)
              .size
              .map do |(country, risk), total|
                counts.append(monitoree_count(analytic_id, active_monitoring, 'Exposure Country', country, risk, total))
              end
    # Total
    monitorees.monitoring_active(active_monitoring)
              .where.not(potential_exposure_country: [nil, ''])
              .group(:exposure_risk_assessment).order(:exposure_risk_assessment)
              .size
              .map do |risk_level, total|
                counts.append(monitoree_count(analytic_id, active_monitoring, 'Exposure Country', 'Total', risk_level, total))
              end
    counts
  end

  # Monitoree counts by last date of exposure by days
  def self.monitoree_counts_by_last_exposure_date(analytic_id, monitorees, active_monitoring)
    monitorees.monitoring_active(active_monitoring)
              .exposed_in_time_frame(NUM_PAST_EXPOSURE_DAYS.days.ago.to_date.to_datetime)
              .group(:last_date_of_exposure, :exposure_risk_assessment)
              .order(:last_date_of_exposure, :exposure_risk_assessment)
              .size
              .map do |(date, risk), total|
                monitoree_count(analytic_id, active_monitoring, 'Last Exposure Date', date, risk, total)
              end
  end

  # Monitoree counts by last date of exposure by weeks
  def self.monitoree_counts_by_last_exposure_week(analytic_id, monitorees, active_monitoring)
    exposure_weeks = <<-SQL
      DATE_ADD(last_date_of_exposure, INTERVAL(1 - DAYOFWEEK(last_date_of_exposure)) DAY)
    SQL
    monitorees.monitoring_active(active_monitoring)
              .exposed_in_time_frame(NUM_PAST_EXPOSURE_WEEKS.weeks.ago.to_date.to_datetime)
              .group(exposure_weeks, :exposure_risk_assessment)
              .order(Arel.sql(exposure_weeks), :exposure_risk_assessment)
              .size
              .map do |(week, risk), total|
                monitoree_count(analytic_id, active_monitoring, 'Last Exposure Week', week, risk, total)
              end
  end

  # Monitoree counts by last date of exposure by months
  def self.monitoree_counts_by_last_exposure_month(analytic_id, monitorees, active_monitoring)
    exposure_months = <<-SQL
      DATE_FORMAT(last_date_of_exposure ,'%Y-%m-01')
    SQL
    monitorees.monitoring_active(active_monitoring)
              .exposed_in_time_frame(NUM_PAST_EXPOSURE_MONTHS.months.ago.to_date.to_datetime)
              .group(exposure_months, :exposure_risk_assessment)
              .order(Arel.sql(exposure_months), :exposure_risk_assessment)
              .size
              .map do |(month, risk), total|
                monitoree_count(analytic_id, active_monitoring, 'Last Exposure Month', month, risk, total)
              end
  end

  # New monitoree count with given fields
  def self.monitoree_count(analytic_id, active_monitoring, category_type, category, risk_level, total, status = nil) # rubocop:todo Metrics/ParameterLists
    MonitoreeCount.new(
      analytic_id: analytic_id,
      active_monitoring: active_monitoring,
      category_type: category_type,
      category: category,
      risk_level: risk_level.nil? ? 'Missing' : risk_level,
      total: total,
      status: status.nil? ? 'Missing' : status,
    )
  end

  # Monitoree flow over time and monitoree action summary
  def self.all_monitoree_snapshots(analytic_id, monitorees, jurisdiction_id)
    MONITOREE_SNAPSHOT_TIME_FRAMES.map do |time_frame|
      MonitoreeSnapshot.new(
        analytic_id: analytic_id,
        time_frame: time_frame,
        new_enrollments: monitorees.enrolled_in_time_frame(time_frame).size,
        transferred_in: Transfer.with_incoming_jurisdiction_id(jurisdiction_id).in_time_frame(time_frame).size,
        closed: monitorees.monitoring_closed.closed_in_time_frame(time_frame).size,
        transferred_out: Transfer.with_outgoing_jurisdiction_id(jurisdiction_id).in_time_frame(time_frame).size
      )
    end
  end

  # Compute state level maps
  def self.state_level_maps(analytic_id, monitorees)
    monitorees.monitoring_open
              .group(:isolation, :address_state)
              .order(:isolation, :address_state)
              .size
              .map do |(isolation, state), total|
                monitoree_map(analytic_id, 'State', isolation ? 'Isolation' : 'Exposure', state, nil, total)
              end
  end

  # Compute county level maps
  def self.county_level_maps(analytic_id, monitorees)
    monitorees.monitoring_open
              .group(:isolation, :address_state, :address_county)
              .order(:isolation, :address_state, :address_county)
              .size
              .map do |(isolation, state, county), total|
                monitoree_map(analytic_id, 'County', isolation ? 'Isolation' : 'Exposure', state, county, total)
              end
  end

  # Monitoree map
  def self.monitoree_map(analytic_id, level, workflow, state, county, total) # rubocop:todo Metrics/ParameterLists
    MonitoreeMap.new(
      analytic_id: analytic_id,
      level: level,
      workflow: workflow,
      state: state,
      county: county,
      total: total
    )
  end
end
