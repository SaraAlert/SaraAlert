require 'active_support'

namespace :analytics do

  desc "Cache Current Analytics"
  MONITORING_STATUSES = ['Symptomatic', 'Non-Reporting', 'Asymptomatic']
  RISK_FACTORS = {
    contact_of_known_case: 'Close Contact with Known Case',
    travel_to_affected_country_or_area: 'Travel to Affected Country or Area',
    was_in_health_care_facility_with_known_cases: 'Was in Healthcare Facility with Known Cases',
    healthcare_personnel: 'Healthcare Personnel',
    member_of_a_common_exposure_cohort: 'Common Exposure Cohort',
    crew_on_passenger_or_cargo_flight: 'Crew on Passenger or Cargo Flight',
    laboratory_personnel: 'Laboratory Personnel'
  }
  MONITOREE_SNAPSHOT_TIME_FRAMES = ['Last 24 Hours', 'Last 14 Days', 'Total']
  NUM_EXPOSURE_COUNTRIES = 5
  NUM_PAST_EXPOSURE_DAYS = 28
  NUM_PAST_EXPOSURE_WEEKS = 53
  NUM_PAST_EXPOSURE_MONTHS = 13

  task cache_current_analytics: :environment do
    jurisdiction_analytic_map = {}

    leaf_nodes = Jurisdiction.leaf_nodes
    leaf_nodes.each do |leaf_jurisdiction|
      leaf_analytic = calculate_analytic_local_to_jurisdiction(leaf_jurisdiction)
      jurisdiction_analytic_map[leaf_jurisdiction.jurisdiction_path_string] = leaf_analytic
      # Start recursive bubble up of analytic data
      add_analytic_to_parent(leaf_jurisdiction, leaf_analytic, jurisdiction_analytic_map)
    end

    # Map data will be on the top-level jurisdiction only
    root_nodes = Jurisdiction.where(ancestry: nil)
    root_nodes.each do |root_jurisdiction|
      symp_by_state = root_jurisdiction.all_patients.pluck(:monitored_address_state).each_with_object(Hash.new(0)) { |state,counts| counts[state] += 1 }
      monitored_by_state = root_jurisdiction.all_patients.symptomatic.pluck(:monitored_address_state).each_with_object(Hash.new(0)) { |state,counts| counts[state] += 1 }
      root_node_path = root_jurisdiction.jurisdiction_path_string
      # These maps can be retrieved back into a hash by running the following
      # JSON.parse <analytic>.monitoree_state_map.to_s.gsub('=>', ':')
      jurisdiction_analytic_map[root_node_path].symptomatic_state_map = symp_by_state.to_s
      jurisdiction_analytic_map[root_node_path].monitoree_state_map = monitored_by_state.to_s
    end
    jurisdiction_analytic_map.each do | jur_path, analytic |
      analytic.save!
    end
  end

  def calculate_analytic_local_to_jurisdiction(jurisdiction)
    analytic  = Analytic.new(jurisdiction_id: jurisdiction.id)
    jurisdiction_monitorees = jurisdiction.immediate_patients
    analytic.monitorees_count = jurisdiction_monitorees.count
    analytic.symptomatic_monitorees_count = jurisdiction_monitorees.symptomatic.count
    analytic.asymptomatic_monitorees_count = jurisdiction_monitorees.asymptomatic.count
    analytic.confirmed_cases_count = jurisdiction_monitorees.confirmed_case.count
    analytic.closed_cases_count = jurisdiction_monitorees.monitoring_closed_with_purged.count
    analytic.open_cases_count = jurisdiction_monitorees.monitoring_open.count
    analytic.non_reporting_monitorees_count = jurisdiction_monitorees.non_reporting.count
    analytic.monitoree_counts = all_monitoree_counts(jurisdiction.all_patients)
    analytic.monitoree_snapshots = all_monitoree_snapshots(jurisdiction.all_patients, jurisdiction.id)
    return analytic
  end

  def add_analytic_to_parent(jurisdiction, analytic, jurisdiction_analytic_map)
    parent = jurisdiction.parent
    if parent == nil
      return
    end
    # Create analytic for patients local to parent if it does not exist
    parent_path_string = parent.jurisdiction_path_string
    parent_analytic = jurisdiction_analytic_map[parent_path_string]
    if parent_analytic == nil
      parent_analytic = calculate_analytic_local_to_jurisdiction(parent)
      add_analytic_to_parent(parent, parent_analytic, jurisdiction_analytic_map)
      jurisdiction_analytic_map[parent_path_string] = parent_analytic
    end

    parent_analytic.monitorees_count += analytic.monitorees_count
    parent_analytic.symptomatic_monitorees_count += analytic.symptomatic_monitorees_count
    parent_analytic.asymptomatic_monitorees_count += analytic.asymptomatic_monitorees_count
    parent_analytic.confirmed_cases_count += analytic.confirmed_cases_count
    parent_analytic.closed_cases_count += analytic.closed_cases_count
    parent_analytic.open_cases_count += analytic.open_cases_count
    parent_analytic.non_reporting_monitorees_count += analytic.non_reporting_monitorees_count

    add_analytic_to_parent(parent, analytic, jurisdiction_analytic_map)
  end

  # Compute all monitoree counts
  def all_monitoree_counts(monitorees)
    counts = []

    # Active and overall total counts
    counts.concat(monitoree_counts_by_total(monitorees, true))
    counts.concat(monitoree_counts_by_total(monitorees, false))

    # Monitoring status counts for today's reporting summary
    counts.concat(monitoree_counts_by_monitoring_status(monitorees))

    # Active and overall counts for epidemiological summary
    counts.concat(monitoree_counts_by_age_group(monitorees, true))
    counts.concat(monitoree_counts_by_age_group(monitorees, false))
    counts.concat(monitoree_counts_by_sex(monitorees, true))
    counts.concat(monitoree_counts_by_sex(monitorees, false))
    counts.concat(monitoree_counts_by_risk_factor(monitorees, true))
    counts.concat(monitoree_counts_by_risk_factor(monitorees, false))
    counts.concat(monitoree_counts_by_exposure_country(monitorees, true))
    counts.concat(monitoree_counts_by_exposure_country(monitorees, false))

    # Active and overall counts for date of last exposure
    counts.concat(monitoree_counts_by_last_exposure_date(monitorees, true))
    counts.concat(monitoree_counts_by_last_exposure_date(monitorees, false))
    counts.concat(monitoree_counts_by_last_exposure_week(monitorees, true))
    counts.concat(monitoree_counts_by_last_exposure_week(monitorees, false))
    counts.concat(monitoree_counts_by_last_exposure_month(monitorees, true))
    counts.concat(monitoree_counts_by_last_exposure_month(monitorees, false))

    counts
  end

  # Total monitoree counts
  def monitoree_counts_by_total(monitorees, active_monitoring)
    monitorees.monitoring_active(active_monitoring)
              .group(:exposure_risk_assessment)
              .order(:exposure_risk_assessment)
              .count.map { |risk_level, total|
                monitoree_count(active_monitoring, 'Overall Total', 'Total', risk_level, total)
              }
  end

  # Monitoree counts by monitoring status (symptomatic, non-reporting, asymptomatic)
  def monitoree_counts_by_monitoring_status(monitorees)
    counts = []
    MONITORING_STATUSES.each { |monitoring_status|
      monitorees.monitoring_status(monitoring_status)
                .group(:exposure_risk_assessment)
                .order(:exposure_risk_assessment)
                .count
                .each { |risk_level, total|
                  counts.append(monitoree_count(true, 'Monitoring Status', monitoring_status, risk_level, total))
                }
    }
    counts
  end

  # Monitoree counts by age group
  def monitoree_counts_by_age_group(monitorees, active_monitoring)
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
              .count
              .map { |fields, total|
                monitoree_count(active_monitoring, 'Age Group', fields[0], fields[1], total)
              }
  end

  # Monitoree counts by sex
  def monitoree_counts_by_sex(monitorees, active_monitoring)
    monitorees.monitoring_active(active_monitoring)
              .group(:sex, :exposure_risk_assessment)
              .order(:sex, :exposure_risk_assessment)
              .count
              .map { |fields, total|
                monitoree_count(active_monitoring, 'Sex', fields[0].nil? ? 'Missing' : fields[0], fields[1], total)
              }
  end

  # Monitoree counts by exposure risk factors
  def monitoree_counts_by_risk_factor(monitorees, active_monitoring)
    counts = []
    # Individual risk factors
    RISK_FACTORS.each do |risk_factor, label|
      monitorees.monitoring_active(active_monitoring)
                .where(risk_factor => true)
                .group(risk_factor, :exposure_risk_assessment)
                .order(:exposure_risk_assessment)
                .count
                .map { |fields, total|
                  counts.append(monitoree_count(active_monitoring, 'Risk Factor', label, fields[1], total))
                }
    end
    # Total
    monitorees.monitoring_active(active_monitoring)
              .where(RISK_FACTORS.keys.join(' OR '))
              .group(:exposure_risk_assessment)
              .order(:exposure_risk_assessment)
              .count
              .map { |risk_level, total|
                counts.append(monitoree_count(active_monitoring, 'Risk Factor', 'Total', risk_level, total))
              }
    counts
  end

  # Monitoree counts by exposure country
  def monitoree_counts_by_exposure_country(monitorees, active_monitoring)
    counts = []
    # Individual countries
    exposure_countries = monitorees.monitoring_active(active_monitoring)
                                   .group(:potential_exposure_country)
                                   .order(count_potential_exposure_country: :desc)
                                   .order(:potential_exposure_country)
                                   .limit(NUM_EXPOSURE_COUNTRIES)
                                   .count(:potential_exposure_country)
                                   .map { |c| c[0] }
    monitorees.monitoring_active(active_monitoring)
              .where(:potential_exposure_country => exposure_countries)
              .group(:potential_exposure_country, :exposure_risk_assessment)
              .order(:potential_exposure_country, :exposure_risk_assessment)
              .count
              .map { |fields, total|
                counts.append(monitoree_count(active_monitoring, 'Exposure Country', fields[0], fields[1], total))
              }
    # Total
    monitorees.monitoring_active(active_monitoring)
              .where.not(potential_exposure_country: [nil, ''])
              .group(:exposure_risk_assessment).order(:exposure_risk_assessment)
              .count
              .map { |risk_level, total|
                counts.append(monitoree_count(active_monitoring, 'Exposure Country', 'Total', risk_level, total))
              }
    counts
  end

  # Monitoree counts by last date of exposure by days
  def monitoree_counts_by_last_exposure_date(monitorees, active_monitoring)
    monitorees.monitoring_active(active_monitoring)
              .exposed_in_time_frame(NUM_PAST_EXPOSURE_DAYS.days.ago.to_date.to_datetime)
              .group(:last_date_of_exposure, :exposure_risk_assessment)
              .order(:last_date_of_exposure, :exposure_risk_assessment)
              .count
              .map { |fields, total|
                monitoree_count(active_monitoring, 'Last Exposure Date', fields[0], fields[1], total)
              }
  end

  # Monitoree counts by last date of exposure by weeks
  def monitoree_counts_by_last_exposure_week(monitorees, active_monitoring)
    exposure_weeks = <<-SQL
      DATE_ADD(last_date_of_exposure, interval -WEEKDAY(last_date_of_exposure)-1 day) 
    SQL
    monitorees.monitoring_active(active_monitoring)
              .exposed_in_time_frame(NUM_PAST_EXPOSURE_WEEKS.weeks.ago.to_date.to_datetime)
              .group(exposure_weeks, :exposure_risk_assessment)
              .order(Arel.sql(exposure_weeks), :exposure_risk_assessment)
              .count
              .map { |fields, total|
                monitoree_count(active_monitoring, 'Last Exposure Week', fields[0], fields[1], total)
              }
  end

  # Monitoree counts by last date of exposure by months
  def monitoree_counts_by_last_exposure_month(monitorees, active_monitoring)
    exposure_months = <<-SQL
      DATE_FORMAT(last_date_of_exposure ,'%Y-%m-01')
    SQL
    monitorees.monitoring_active(active_monitoring)
              .exposed_in_time_frame(NUM_PAST_EXPOSURE_MONTHS.months.ago.to_date.to_datetime)
              .group(exposure_months, :exposure_risk_assessment)
              .order(Arel.sql(exposure_months), :exposure_risk_assessment)
              .count
              .map { |fields, total|
                monitoree_count(active_monitoring, 'Last Exposure Month', fields[0], fields[1], total)
              }
  end

  # New monitoree count with given fields
  def monitoree_count(active_monitoring, category_type, category, risk_level, total)
    MonitoreeCount.new(
      active_monitoring: active_monitoring,
      category_type: category_type,
      category: category,
      risk_level: risk_level.nil? ? 'Missing' : risk_level,
      total: total
    )
  end

  # Monitoree flow over time and monitoree action summary
  def all_monitoree_snapshots(monitorees, jurisdiction_id)
    MONITOREE_SNAPSHOT_TIME_FRAMES.map { |time_frame|
      MonitoreeSnapshot.new(
        time_frame: time_frame,
        new_enrollments: monitorees.enrolled_in_time_frame(time_frame).count,
        transferred_in: Transfer.with_incoming_jurisdiction_id(jurisdiction_id).in_time_frame(time_frame).count,
        closed: monitorees.monitoring_closed.joins(:histories).merge(History.not_monitoring.in_time_frame(time_frame)).count,
        transferred_out: Transfer.with_outgoing_jurisdiction_id(jurisdiction_id).in_time_frame(time_frame).count,
        referral_for_medical_evaluation: monitorees.joins(:histories).merge(History.referral_for_medical_evaluation.in_time_frame(time_frame)).count,
        document_completed_medical_evaluation: monitorees.joins(:histories).merge(History.document_completed_medical_evaluation.in_time_frame(time_frame)).count,
        document_medical_evaluation_summary_and_plan: monitorees.joins(:histories).merge(History.document_medical_evaluation_summary_and_plan.in_time_frame(time_frame)).count,
        referral_for_public_health_test: monitorees.joins(:histories).merge(History.referral_for_public_health_test.in_time_frame(time_frame)).count,
        public_health_test_specimen_received_by_lab_results_pending: monitorees.joins(:histories).merge(History.public_health_test_specimen_received_by_lab_results_pending.in_time_frame(time_frame)).count,
        results_of_public_health_test_positive: monitorees.joins(:histories).merge(History.results_of_public_health_test_positive.in_time_frame(time_frame)).count,
        results_of_public_health_test_negative: monitorees.joins(:histories).merge(History.results_of_public_health_test_negative.in_time_frame(time_frame)).count,
      )
    }
  end
end
