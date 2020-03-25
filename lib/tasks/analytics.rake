require 'active_support'

namespace :analytics do

  desc "Cache Current Analytics"
  
  RISK_LEVELS = ['High', 'Medium', 'Low', 'No Identified Risk', nil]
  MONITORING_STATUSES = ['Symptomatic', 'Non-Reporting', 'Asymptomatic']
  SEXES = ['Male', 'Female', 'Unknown']
  AGE_GROUPS = ['0-19', '20-29', '30-39', '40-49', '50-59', '60-69', '70-79', '>=80']
  RISK_FACTORS = [
    'Close Contact with Known Case',
    'Travel to Affected Country or Area',
    'Was in Healthcare Facility with Known Cases',
    'Healthcare Personnel',
    'Common Exposure Cohort',
    'Crew on Passenger or Cargo Flight',
    'Laboratory Personnel',
    'Total'
  ]
  MONITOREE_SNAPSHOT_TIME_FRAMES = ['Last 24 Hours', 'Last 14 Days', 'Total']
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
    analytic.monitoree_counts = all_monitoree_counts(jurisdiction_monitorees)
    analytic.monitoree_snapshots = all_monitoree_snapshots(jurisdiction_monitorees, jurisdiction.id)
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

  def all_monitoree_counts(monitorees)
    all_monitoree_counts = []
    all_monitoree_counts.concat(monitoree_counts_by_totals(monitorees))
    all_monitoree_counts.concat(monitoree_counts_by_monitoring_statuses(monitorees))
    all_monitoree_counts.concat(monitoree_counts_by_age_groups(monitorees))
    all_monitoree_counts.concat(monitoree_counts_by_sexes(monitorees))
    all_monitoree_counts.concat(monitoree_counts_by_risk_factors(monitorees))
    all_monitoree_counts.concat(monitoree_counts_by_exposure_countries(monitorees))
    all_monitoree_counts.concat(monitoree_counts_by_last_exposure_date(monitorees))
    all_monitoree_counts.concat(monitoree_counts_by_last_exposure_week(monitorees))
    all_monitoree_counts.concat(monitoree_counts_by_last_exposure_month(monitorees))
    all_monitoree_counts
  end
  
  def monitoree_counts_by_totals(monitorees)
    monitorees.group(:monitoring, :exposure_risk_assessment).count.map { |fields, total|
      monitoree_count(fields[0], 'Total', 'Total', fields[1], total)
    }
  end

  def monitoree_counts_by_monitoring_statuses(monitorees)
    monitorees.symptomatic.group(:exposure_risk_assessment).count.map { |risk_level, total|
      monitoree_count(true, 'Monitoring Status', 'Symptomatic', risk_level, total)
    }
    monitorees.non_reporting.group(:exposure_risk_assessment).count.map { |risk_level, total|
      monitoree_count(true, 'Monitoring Status', 'Non-Reporting', risk_level, total)
    }
    monitorees.asymptomatic.group(:exposure_risk_assessment).count.map { |risk_level, total|
      monitoree_count(true, 'Monitoring Status', 'Asymptomatic', risk_level, total)
    }
  end

  def monitoree_counts_by_age_groups(monitorees)
    query = <<-SQL
      SELECT
        monitoring,
        CASE
          WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) < 20 THEN '0-19'
          WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) >= 20 AND EXTRACT(YEAR FROM AGE(date_of_birth)) < 30 THEN '20-29'
          WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) >= 30 AND EXTRACT(YEAR FROM AGE(date_of_birth)) < 40 THEN '30-39'
          WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) >= 40 AND EXTRACT(YEAR FROM AGE(date_of_birth)) < 50 THEN '40-49'
          WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) >= 50 AND EXTRACT(YEAR FROM AGE(date_of_birth)) < 60 THEN '50-59'
          WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) >= 60 AND EXTRACT(YEAR FROM AGE(date_of_birth)) < 70 THEN '60-69'
          WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) >= 70 AND EXTRACT(YEAR FROM AGE(date_of_birth)) < 80 THEN '70-79'
          WHEN EXTRACT(YEAR FROM AGE(date_of_birth)) >= 80 THEN '>=80'
        END AS category,
        exposure_risk_assessment,
        COUNT(*) AS total
      FROM patients
      GROUP BY monitoring, category, exposure_risk_assessment
    SQL
    ActiveRecord::Base.connection.exec_query(query).rows.map { |row|
      monitoree_count(row[0], 'Sex', row[1], row[2], row[3])
    }
  end

  def monitoree_counts_by_sexes(monitorees)
    monitorees.group(:monitoring, :sex, :exposure_risk_assessment).count.map { |fields, total|
      monitoree_count(fields[0], 'Sex', fields[1], fields[2], total)
    }
  end

  def monitoree_counts_by_risk_factors(monitorees)
    monitoree_counts = []
    monitorees.group(:monitoring, :contact_of_known_case, :exposure_risk_assessment).count.map { |fields, total|
      monitoree_counts.append(monitoree_count(fields[0], 'Risk Factor', 'Close Contact with Known Case', fields[2], total))
    }
    monitorees.group(:monitoring, :travel_to_affected_country_or_area, :exposure_risk_assessment).count.map { |fields, total|
      monitoree_counts.append(monitoree_count(fields[0], 'Risk Factor', 'Travel to Affected Country or Area', fields[2], total))
    }
    monitorees.group(:monitoring, :was_in_health_care_facility_with_known_cases, :exposure_risk_assessment).count.map { |fields, total|
      monitoree_counts.append(monitoree_count(fields[0], 'Risk Factor', 'Was in Healthcare Facility with Known Cases', fields[2], total))
    }
    monitorees.group(:monitoring, :healthcare_personnel, :exposure_risk_assessment).count.map { |fields, total|
      monitoree_counts.append(monitoree_count(fields[0], 'Risk Factor', 'Healthcare Personnel', fields[2], total))
    }
    monitorees.group(:monitoring, :member_of_a_common_exposure_cohort, :exposure_risk_assessment).count.map { |fields, total|
      monitoree_counts.append(monitoree_count(fields[0], 'Risk Factor', 'Common Exposure Cohort', fields[2], total))
    }
    monitorees.group(:monitoring, :crew_on_passenger_or_cargo_flight, :exposure_risk_assessment).count.map { |fields, total|
      monitoree_counts.append(monitoree_count(fields[0], 'Risk Factor', 'Crew on Passenger or Cargo Flight', fields[2], total))
    }
    monitorees.group(:monitoring, :laboratory_personnel, :exposure_risk_assessment).count.map { |fields, total|
      monitoree_counts.append(monitoree_count(fields[0], 'Risk Factor', 'Laboratory Personnel', fields[2], total))
    }
    monitoree_counts
  end

  def monitoree_counts_by_exposure_countries(monitorees)
    monitorees.group(:monitoring, :potential_exposure_country, :exposure_risk_assessment).count.map { |fields, total| 
      monitoree_count(fields[0], 'Exposure Country', fields[1], fields[2], total)
    }
  end

  def monitoree_counts_by_last_exposure_date(monitorees)
    query = <<-SQL
      SELECT monitoring, DATE_TRUNC('day', last_date_of_exposure::date)::date AS category, exposure_risk_assessment, COUNT(*)
      FROM patients
      WHERE last_date_of_exposure > (CURRENT_DATE - '28 days'::interval)
      GROUP BY monitoring, last_date_of_exposure, exposure_risk_assessment
    SQL
    ActiveRecord::Base.connection.exec_query(query).rows.map { |row|
      monitoree_count(row[0], 'Last Exposure Date', row[1], row[2], row[3])
    }
  end

  def monitoree_counts_by_last_exposure_week(monitorees)
    query = <<-SQL
      SELECT monitoring, (DATE_TRUNC('week', last_date_of_exposure::date) - '1 day'::interval)::date AS category, exposure_risk_assessment, COUNT(*)
      FROM patients
      WHERE last_date_of_exposure > (CURRENT_DATE - '53 weeks'::interval)
      GROUP BY monitoring, last_date_of_exposure, exposure_risk_assessment
    SQL
    ActiveRecord::Base.connection.exec_query(query).rows.map { |row|
      monitoree_count(row[0], 'Last Exposure Week', row[1], row[2], row[3])
    }
  end

  def monitoree_counts_by_last_exposure_month(monitorees)
    query = <<-SQL
      SELECT monitoring, DATE_TRUNC('month', last_date_of_exposure::date)::date AS category, exposure_risk_assessment, COUNT(*)
      FROM patients
      WHERE last_date_of_exposure > (CURRENT_DATE - '13 months'::interval)
      GROUP BY monitoring, last_date_of_exposure, exposure_risk_assessment
    SQL
    ActiveRecord::Base.connection.exec_query(query).rows.map { |row|
      monitoree_count(row[0], 'Last Exposure Month', row[1], row[2], row[3])
    }
  end

  def monitoree_count(active_monitoring, category_type, category, risk_level, total)
    MonitoreeCount.new(
      active_monitoring: active_monitoring,
      category_type: category_type,
      category: category,
      risk_level: risk_level.nil? ? 'Missing' : risk_level,
      total: total
    )
  end

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
