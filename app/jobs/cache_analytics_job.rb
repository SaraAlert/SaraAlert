# frozen_string_literal: true

# CacheAnalyticsJob: caches the latest available analytics
class CacheAnalyticsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Analytic.transaction do
      analytics_by_jur_path = {}
      root_jurs = []

      leaf_nodes = Jurisdiction.all.select { |jur| jur.has_children? == false }
      leaf_nodes.each do |leaf_jurisdiction|
        leaf_analytic = self.class.calculate_analytic_local_to_jurisdiction(leaf_jurisdiction)
        analytics_by_jur_path[leaf_jurisdiction[:path]] = leaf_analytic
        # Start recursive bubble up of analytic data
        self.class.add_analytic_to_parent(leaf_jurisdiction, leaf_analytic, analytics_by_jur_path)
      end

      # Map data will be on the top-level jurisdiction only
      root_nodes = Jurisdiction.where(ancestry: nil)
      root_nodes.each do |root_jurisdiction|
        symp_by_state = root_jurisdiction.all_patients.pluck(:address_state).each_with_object(Hash.new(0)) { |state, counts| counts[state] += 1 }
        monitored_by_state = root_jurisdiction.all_patients.symptomatic.uniq.pluck(:address_state).each_with_object(Hash.new(0)) do |state, counts|
          counts[state] += 1
        end
        root_node_path = root_jurisdiction[:path]
        # These maps can be retrieved back into a hash by running the following
        # JSON.parse <analytic>.monitoree_state_map.to_s.gsub('=>', ':')
        analytics_by_jur_path[root_node_path].symptomatic_state_map = symp_by_state.to_s
        analytics_by_jur_path[root_node_path].monitoree_state_map = monitored_by_state.to_s
        root_jurs.append(root_jurisdiction[:id])
      end
      analytics_by_jur_path.each do |_jur_path, analytic|
        analytic.save!
        patients = Jurisdiction.find(analytic.jurisdiction_id).all_patients
        MonitoreeCount.import! self.class.all_monitoree_counts(analytic.id, patients)
        MonitoreeSnapshot.import! self.class.all_monitoree_snapshots(analytic.id, patients, analytic.jurisdiction_id)
        if root_jurs.include?(analytic.jurisdiction_id)
          MonitoreeMap.import! self.class.all_monitoree_maps(analytic.id, patients)
        end
      end
    end
  end

  MONITORING_STATUSES ||= %w[Symptomatic Non-Reporting Asymptomatic].freeze
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

  def self.calculate_analytic_local_to_jurisdiction(jurisdiction)
    analytic = Analytic.new(jurisdiction_id: jurisdiction.id)
    jurisdiction_monitorees = jurisdiction.immediate_patients
    analytic.monitorees_count = jurisdiction_monitorees.size
    analytic.symptomatic_monitorees_count = jurisdiction_monitorees.symptomatic.size
    analytic.asymptomatic_monitorees_count = jurisdiction_monitorees.asymptomatic.size
    analytic.confirmed_cases_count = jurisdiction_monitorees.confirmed_case.size
    analytic.closed_cases_count = jurisdiction_monitorees.monitoring_closed_with_purged.size
    analytic.open_cases_count = jurisdiction_monitorees.monitoring_open.size
    analytic.non_reporting_monitorees_count = jurisdiction_monitorees.non_reporting.size
    analytic
  end

  def self.add_analytic_to_parent(jurisdiction, analytic, analytics_by_jur_path)
    parent = jurisdiction.parent
    return if parent.nil?

    # Create analytic for patients local to parent if it does not exist
    parent_path_string = parent[:path]
    parent_analytic = analytics_by_jur_path[parent_path_string]
    if parent_analytic.nil?
      parent_analytic = calculate_analytic_local_to_jurisdiction(parent)
      add_analytic_to_parent(parent, parent_analytic, analytics_by_jur_path)
      analytics_by_jur_path[parent_path_string] = parent_analytic
    end

    parent_analytic.monitorees_count += analytic.monitorees_count
    parent_analytic.symptomatic_monitorees_count += analytic.symptomatic_monitorees_count
    parent_analytic.asymptomatic_monitorees_count += analytic.asymptomatic_monitorees_count
    parent_analytic.confirmed_cases_count += analytic.confirmed_cases_count
    parent_analytic.closed_cases_count += analytic.closed_cases_count
    parent_analytic.open_cases_count += analytic.open_cases_count
    parent_analytic.non_reporting_monitorees_count += analytic.non_reporting_monitorees_count

    add_analytic_to_parent(parent, analytic, analytics_by_jur_path)
  end

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
              .map do |fields, total|
                monitoree_count(analytic_id, active_monitoring, 'Age Group', fields[0], fields[1], total)
              end
  end

  # Monitoree counts by sex
  def self.monitoree_counts_by_sex(analytic_id, monitorees, active_monitoring)
    monitorees.monitoring_active(active_monitoring)
              .group(:sex, :exposure_risk_assessment)
              .order(:sex, :exposure_risk_assessment)
              .size
              .map do |fields, total|
                monitoree_count(analytic_id, active_monitoring, 'Sex', fields[0].nil? ? 'Missing' : fields[0], fields[1], total)
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
                .map do |fields, total|
                  counts.append(monitoree_count(analytic_id, active_monitoring, 'Risk Factor', label, fields[1], total))
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
              .map do |fields, total|
                counts.append(monitoree_count(analytic_id, active_monitoring, 'Exposure Country', fields[0], fields[1], total))
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
              .map do |fields, total|
                monitoree_count(analytic_id, active_monitoring, 'Last Exposure Date', fields[0], fields[1], total)
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
              .map do |fields, total|
                monitoree_count(analytic_id, active_monitoring, 'Last Exposure Week', fields[0], fields[1], total)
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
              .map do |fields, total|
                monitoree_count(analytic_id, active_monitoring, 'Last Exposure Month', fields[0], fields[1], total)
              end
  end

  # New monitoree count with given fields
  def self.monitoree_count(analytic_id, active_monitoring, category_type, category, risk_level, total) # rubocop:todo Metrics/ParameterLists
    MonitoreeCount.new(
      analytic_id: analytic_id,
      active_monitoring: active_monitoring,
      category_type: category_type,
      category: category,
      risk_level: risk_level.nil? ? 'Missing' : risk_level,
      total: total
    )
  end

  # Monitoree flow over time and monitoree action summary
  def self.all_monitoree_snapshots(analytic_id, monitorees, jurisdiction_id)
    # rubocop:disable Layout/LineLength
    MONITOREE_SNAPSHOT_TIME_FRAMES.map do |time_frame|
      MonitoreeSnapshot.new(
        analytic_id: analytic_id,
        time_frame: time_frame,
        new_enrollments: monitorees.enrolled_in_time_frame(time_frame).size,
        transferred_in: Transfer.with_incoming_jurisdiction_id(jurisdiction_id).in_time_frame(time_frame).size,
        closed: monitorees.monitoring_closed.closed_in_time_frame(time_frame).size,
        transferred_out: Transfer.with_outgoing_jurisdiction_id(jurisdiction_id).in_time_frame(time_frame).size,
        referral_for_medical_evaluation: monitorees.joins(:histories).merge(History.referral_for_medical_evaluation.in_time_frame(time_frame)).size,
        document_completed_medical_evaluation: monitorees.joins(:histories).merge(History.document_completed_medical_evaluation.in_time_frame(time_frame)).size,
        document_medical_evaluation_summary_and_plan: monitorees.joins(:histories).merge(History.document_medical_evaluation_summary_and_plan.in_time_frame(time_frame)).size,
        referral_for_public_health_test: monitorees.joins(:histories).merge(History.referral_for_public_health_test.in_time_frame(time_frame)).size,
        public_health_test_specimen_received_by_lab_results_pending: monitorees.joins(:histories).merge(History.public_health_test_specimen_received_by_lab_results_pending.in_time_frame(time_frame)).size,
        results_of_public_health_test_positive: monitorees.joins(:histories).merge(History.results_of_public_health_test_positive.in_time_frame(time_frame)).size,
        results_of_public_health_test_negative: monitorees.joins(:histories).merge(History.results_of_public_health_test_negative.in_time_frame(time_frame)).size
      )
    end
    # rubocop:enable Layout/LineLength
  end

  # Compute all monitoree maps
  def self.all_monitoree_maps(analytic_id, monitorees)
    maps = []
    monitorees.monitoring_open
              .group(:isolation, :address_state)
              .order(:isolation, :address_state)
              .size
              .map do |(isolation, state), total|
                workflow = isolation ? 'Isolation' : 'Exposure'
                maps.append(monitoree_map(analytic_id, 'State', workflow, state, nil, total))
              end
    monitorees.monitoring_open
              .group(:isolation, :address_state, :address_county)
              .order(:isolation, :address_state, :address_county)
              .size
              .map do |(isolation, state, county), total|
                workflow = isolation ? 'Isolation' : 'Exposure'
                maps.append(monitoree_map(analytic_id, 'County', workflow, state, county, total))
              end
    maps
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
