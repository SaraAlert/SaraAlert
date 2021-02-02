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
        patients = jur.all_patients_including_purged
        MonitoreeCount.import! self.class.all_monitoree_counts(analytic.id, patients)
        MonitoreeMap.import! self.class.state_level_maps(analytic.id, patients)
        MonitoreeMap.import! self.class.county_level_maps(analytic.id, patients) unless jur.root?
        MonitoreeSnapshot.import! self.class.all_monitoree_snapshots(analytic.id, patients, jur.subtree_ids)
      end
      cached << { id: jur.id, name: jur.jurisdiction_path_string }
    rescue StandardError => e
      not_cached << { id: jur.id, name: jur.jurisdiction_path_string, reason: e.message }
      next
    end

    # Send results
    UserMailer.cache_analytics_job_email(cached, not_cached, Jurisdiction.count).deliver_now
  end

  WORKFLOWS = %w[Exposure Isolation].freeze
  MONITORING_STATUSES ||= %w[Symptomatic Non-Reporting Asymptomatic].freeze
  LINELIST_STATUSES = [
    'Exposure Symptomatic',
    'Exposure Non-Reporting',
    'Exposure Asymptomatic',
    'Exposure PUI',
    'Isolation Requiring Review',
    'Isolation Non-Reporting',
    'Isolation Reporting'
  ].freeze
  RISK_FACTORS ||= {
    contact_of_known_case: 'Close Contact with Known Case',
    travel_to_affected_country_or_area: 'Travel from Affected Country or Area',
    was_in_health_care_facility_with_known_cases: 'Was in Healthcare Facility with Known Cases',
    healthcare_personnel: 'Healthcare Personnel',
    member_of_a_common_exposure_cohort: 'Common Exposure Cohort',
    crew_on_passenger_or_cargo_flight: 'Crew on Passenger or Cargo Flight',
    laboratory_personnel: 'Laboratory Personnel'
  }.freeze
  MONITOREE_SNAPSHOT_TIME_FRAMES ||= ['Last 24 Hours', 'Last 7 Days', 'Last 14 Days', 'Total'].freeze
  NUM_EXPOSURE_COUNTRIES ||= 5
  NUM_PAST_DAYS ||= 28
  NUM_PAST_WEEKS ||= 53
  NUM_PAST_MONTHS ||= 13

  # Compute all monitoree counts
  def self.all_monitoree_counts(analytic_id, monitorees)
    counts = []

    # Active and overall counts for epidemiological summary
    counts.concat(monitoree_counts_by_age_group(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_sex(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_ethnicity(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_race(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_sexual_orientation(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_reporting_method(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_risk_factor(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_exposure_country(analytic_id, monitorees))

    # Active and overall counts for date of last exposure
    counts.concat(monitoree_counts_by_last_exposure_date(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_last_exposure_week(analytic_id, monitorees))
    counts.concat(monitoree_counts_by_last_exposure_month(analytic_id, monitorees))
    counts
  end

  # Monitoree counts by age group
  def self.monitoree_counts_by_age_group(analytic_id, monitorees)
    counts = []
    # Some jurisdictions are using `1-1-1900` as a "fake birthdate" where data might be invalid or unknown
    # This can skew the `>=80` analytics data, so we collect the count of monitoree's over 110 years old
    # And inform the user that that number is bundled in with `>=80`
    # The client will perform the logic to combine the "FAKE_BIRTHDATE" in with `>=80`
    age_groups = <<-SQL
      CASE
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 20 THEN '0-19'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 20 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 30 THEN '20-29'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 30 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 40 THEN '30-39'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 40 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 50 THEN '40-49'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 50 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 60 THEN '50-59'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 60 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 70 THEN '60-69'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 70 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 80 THEN '70-79'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 80 AND TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 110 THEN '>=80'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 110 THEN 'FAKE_BIRTHDATE'
      END
    SQL
    monitorees.monitoring_active(true)
              .group(age_groups, :isolation)
              .order(Arel.sql(age_groups), :isolation)
              .size
              .map do |(age_group, isolation), total|
                counts.append(monitoree_count(analytic_id,
                                              true,
                                              'Age Group',
                                              age_group.nil? ? 'Missing' : age_group,
                                              total,
                                              isolation ? 'Isolation' : 'Exposure'))
              end
    counts
  end

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

  # Monitoree counts by sex
  def self.monitoree_counts_by_sex(analytic_id, monitorees)
    counts = []
    monitorees.monitoring_active(true)
              .group(:sex, :isolation)
              .order(:sex, :isolation)
              .size
              .map do |(sex, isolation), total|
                counts.append(monitoree_count(analytic_id, true, 'Sex', sex.nil? ? 'Missing' : sex, total, isolation ? 'Isolation' : 'Exposure'))
              end
    counts
  end

  # Monitoree counts by sexual orientation
  def self.monitoree_counts_by_sexual_orientation(analytic_id, monitorees)
    counts = []
    monitorees.monitoring_active(true)
              .group(:sexual_orientation, :isolation)
              .order(:sexual_orientation, :isolation)
              .size
              .map do |(sexual_orientation, isolation), total|
      counts.append(
        monitoree_count(
          analytic_id,
          true,
          'Sexual Orientation',
          sexual_orientation.nil? ? 'Missing' : sexual_orientation,
          total,
          isolation ? 'Isolation' : 'Exposure'
        )
      )
    end
    counts
  end

  # Monitoree counts by race
  def self.monitoree_counts_by_race(analytic_id, monitorees)
    counts = []
    racial_groups = <<-SQL
      (CASE
        WHEN (COALESCE(white, 0) +
              COALESCE(black_or_african_american, 0) +
              COALESCE(asian, 0) +
              COALESCE(american_indian_or_alaska_native, 0) +
              COALESCE(native_hawaiian_or_other_pacific_islander, 0) > 1) THEN 'More Than One Race'
        WHEN (white = 1) THEN "White"
        WHEN (black_or_african_american = 1) THEN "Black or African American"
        WHEN (asian = 1) THEN "Asian"
        WHEN (american_indian_or_alaska_native = 1) THEN "American Indian or Alaska Native"
        WHEN (native_hawaiian_or_other_pacific_islander = 1) THEN "Native Hawaiian or Other Pacific Islander"
        ELSE "Unknown"
      END)
    SQL
    monitorees.monitoring_active(true)
              .group(racial_groups, :isolation)
              .order(Arel.sql(racial_groups), :isolation)
              .size
              .map do |(racial_group, isolation), total|
                counts.append(
                  monitoree_count(analytic_id,
                                  true,
                                  'Race',
                                  racial_group.nil? ? 'Missing' : racial_group,
                                  total,
                                  isolation ? 'Isolation' : 'Exposure')
                )
              end
    counts
  end

  # Monitoree counts by ethnicity
  def self.monitoree_counts_by_ethnicity(analytic_id, monitorees)
    counts = []
    monitorees.monitoring_active(true)
              .group(:ethnicity, :isolation)
              .order(:ethnicity, :isolation)
              .size
              .map do |(ethnicity, isolation), total|
                counts.append(monitoree_count(analytic_id,
                                              true,
                                              'Ethnicity',
                                              ethnicity.nil? ? 'Missing' : ethnicity,
                                              total,
                                              isolation ? 'Isolation' : 'Exposure'))
              end
    counts
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
                  counts.append(
                    monitoree_count(analytic_id,
                                    true,
                                    'Contact Method',
                                    preferred_contact_method.nil? ? 'Missing' : preferred_contact_method,
                                    total,
                                    linelist_status)
                  )
                end
    end
    counts
  end

  # Monitoree counts by exposure risk factors
  def self.monitoree_counts_by_risk_factor(analytic_id, monitorees)
    counts = []
    RISK_FACTORS.each do |risk_factor, label|
      monitorees.monitoring_active(true)
                .where(risk_factor => true)
                .group(risk_factor, :isolation)
                .size
                .map do |(_, isolation), total|
                  counts.append(monitoree_count(analytic_id, true, 'Risk Factor', label, total, isolation ? 'Isolation' : 'Exposure'))
                end
    end
    counts
  end

  # Monitoree counts by exposure country
  def self.monitoree_counts_by_exposure_country(analytic_id, monitorees)
    counts = []
    exposure_countries = monitorees.monitoring_active(true)
                                   .where.not(potential_exposure_country: nil)
                                   .group(:potential_exposure_country)
                                   .order(count_potential_exposure_country: :desc)
                                   .order(:potential_exposure_country)
                                   .limit(NUM_EXPOSURE_COUNTRIES)
                                   .count(:potential_exposure_country)
                                   .map { |c| c[0] }
    monitorees.monitoring_active(true)
              .where(potential_exposure_country: exposure_countries)
              .group(:potential_exposure_country, :isolation)
              .order(:potential_exposure_country, :isolation)
              .size
              .map do |(country, isolation), total|
      counts.append(monitoree_count(analytic_id, true, 'Exposure Country', country, total, isolation ? 'Isolation' : 'Exposure'))
    end
    counts
  end

  # Monitoree counts by last date of exposure by days
  def self.monitoree_counts_by_last_exposure_date(analytic_id, monitorees)
    counts = []

    monitorees.where(isolation: false)
              .monitoring_active(true)
              .exposed_in_time_frame(NUM_PAST_DAYS.days.ago.to_date.to_datetime)
              .group(:last_date_of_exposure)
              .order(:last_date_of_exposure)
              .size
              .map do |date, total|
                counts.append(monitoree_count(analytic_id, true, 'Last Exposure Date', date, total, 'Exposure'))
              end

    monitorees.where(isolation: true)
              .monitoring_active(true)
              .symptom_onset_in_time_frame(NUM_PAST_DAYS.days.ago.to_date.to_datetime)
              .group(:symptom_onset)
              .order(:symptom_onset)
              .size
              .map do |date, total|
                counts.append(monitoree_count(analytic_id, true, 'Last Exposure Date', date, total, 'Isolation'))
              end
    counts
  end

  # Monitoree counts by last date of exposure by weeks
  def self.monitoree_counts_by_last_exposure_week(analytic_id, monitorees)
    counts = []
    exposure_weeks = <<-SQL
      DATE_ADD(last_date_of_exposure, INTERVAL(1 - DAYOFWEEK(last_date_of_exposure)) DAY)
    SQL
    symptom_onset_weeks = <<-SQL
      DATE_ADD(symptom_onset, INTERVAL(1 - DAYOFWEEK(symptom_onset)) DAY)
    SQL
    monitorees.where(isolation: false)
              .monitoring_active(true)
              .exposed_in_time_frame(NUM_PAST_WEEKS.weeks.ago.to_date.to_datetime)
              .group(exposure_weeks)
              .order(Arel.sql(exposure_weeks))
              .size
              .map do |week, total|
                counts.append(monitoree_count(analytic_id, true, 'Last Exposure Week', week, total, 'Exposure'))
              end
    monitorees.where(isolation: true)
              .monitoring_active(true)
              .symptom_onset_in_time_frame(NUM_PAST_WEEKS.weeks.ago.to_date.to_datetime)
              .group(symptom_onset_weeks)
              .order(Arel.sql(symptom_onset_weeks))
              .size
              .map do |week, total|
                counts.append(monitoree_count(analytic_id, true, 'Last Exposure Week', week, total, 'Isolation'))
              end
    counts
  end

  # Monitoree counts by last date of exposure by months
  def self.monitoree_counts_by_last_exposure_month(analytic_id, monitorees)
    counts = []
    exposure_months = <<-SQL
      DATE_FORMAT(last_date_of_exposure ,'%Y-%m-01')
    SQL
    symptom_onset_months = <<-SQL
      DATE_FORMAT(symptom_onset ,'%Y-%m-01')
    SQL

    monitorees.where(isolation: false)
              .monitoring_active(true)
              .exposed_in_time_frame(NUM_PAST_MONTHS.months.ago.to_date.to_datetime)
              .group(exposure_months)
              .order(Arel.sql(exposure_months))
              .size
              .map do |month, total|
                counts.append(monitoree_count(analytic_id, true, 'Last Exposure Month', month, total, 'Exposure'))
              end
    monitorees.where(isolation: true)
              .monitoring_active(true)
              .symptom_onset_in_time_frame(NUM_PAST_MONTHS.months.ago.to_date.to_datetime)
              .group(symptom_onset_months)
              .order(Arel.sql(symptom_onset_months))
              .size
              .map do |month, total|
                counts.append(monitoree_count(analytic_id, true, 'Last Exposure Month', month, total, 'Isolation'))
              end
    counts
  end

  # New monitoree count with given fields
  def self.monitoree_count(analytic_id, active_monitoring, category_type, category, total, status)
    MonitoreeCount.new(
      analytic_id: analytic_id,
      active_monitoring: active_monitoring,
      category_type: category_type,
      category: category,
      total: total,
      status: status
    )
  end

  # Monitoree flow over time and monitoree action summary
  def self.all_monitoree_snapshots(analytic_id, monitorees, subjur_ids)
    counts = []
    MONITOREE_SNAPSHOT_TIME_FRAMES.map do |time_frame|
      WORKFLOWS.map do |workflow|
        counts.append(MonitoreeSnapshot.new(
                        analytic_id: analytic_id,
                        time_frame: time_frame,
                        new_enrollments: monitorees.where(isolation: workflow == 'Isolation')
                                                   .enrolled_in_time_frame(time_frame)
                                                   .size,
                        # only transfers from outside this jurisdiction's hierarchy to a jurisdiction within this jurisdiction's hierarchy are included
                        transferred_in: Transfer.where(to_jurisdiction_id: subjur_ids)
                                                .where.not(from_jurisdiction_id: subjur_ids)
                                                .where_assoc_exists(:patient, isolation: workflow == 'Isolation')
                                                .in_time_frame(time_frame)
                                                .size,
                        closed: monitorees.where(isolation: workflow == 'Isolation')
                                          .monitoring_closed
                                          .closed_in_time_frame(time_frame)
                                          .size,
                        # only transfers from within this jurisdiction's hierarchy to a jurisdiction outside this jurisdiction's hierarchy are included
                        transferred_out: Transfer.where(from_jurisdiction_id: subjur_ids)
                                                 .where.not(to_jurisdiction_id: subjur_ids)
                                                 .where_assoc_exists(:patient, isolation: workflow == 'Isolation')
                                                 .in_time_frame(time_frame)
                                                 .size,
                        status: workflow
                      ))
      end
    end
    counts
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
  def self.monitoree_map(analytic_id, level, workflow, state, county, total)
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
