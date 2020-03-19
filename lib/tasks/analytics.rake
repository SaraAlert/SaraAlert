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
    # exposure_countries = monitorees.distinct.pluck(:potential_exposure_country) # all countries that any monitoree has been exposed in
    exposure_countries = monitorees.group(:potential_exposure_country).order(count_potential_exposure_country: :desc).limit(5).count(:potential_exposure_country).map{ |c| c[0] }.append('Total')
    all_monitoree_counts = []
    all_monitoree_counts.concat(monitoree_counts(monitorees, true, 'monitoring_status', MONITORING_STATUSES))
    all_monitoree_counts.concat(monitoree_counts(monitorees, true, 'total', ['overall']))
    all_monitoree_counts.concat(monitoree_counts(monitorees, false, 'total', ['overall']))
    all_monitoree_counts.concat(monitoree_counts(monitorees, true, 'age_group', AGE_GROUPS))
    all_monitoree_counts.concat(monitoree_counts(monitorees, false, 'age_group', AGE_GROUPS))
    all_monitoree_counts.concat(monitoree_counts(monitorees, true, 'sex', SEXES))
    all_monitoree_counts.concat(monitoree_counts(monitorees, false, 'sex', SEXES))
    all_monitoree_counts.concat(monitoree_counts(monitorees, true, 'risk_factor', RISK_FACTORS))
    all_monitoree_counts.concat(monitoree_counts(monitorees, false, 'risk_factor', RISK_FACTORS))
    all_monitoree_counts.concat(monitoree_counts(monitorees, true, 'exposure_country', exposure_countries))
    all_monitoree_counts.concat(monitoree_counts(monitorees, false, 'exposure_country', exposure_countries))
    all_monitoree_counts.concat(monitoree_counts(monitorees, true, 'last_exposure_date', last_exposure_dates))
    all_monitoree_counts.concat(monitoree_counts(monitorees, false, 'last_exposure_date', last_exposure_dates))
    all_monitoree_counts.concat(monitoree_counts(monitorees, false, 'last_exposure_week', last_exposure_weeks))
    all_monitoree_counts.concat(monitoree_counts(monitorees, false, 'last_exposure_month', last_exposure_months))
    all_monitoree_counts
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

  def monitoree_counts(monitorees, active_monitoring, category_type, categories)
    monitoree_counts = []
    RISK_LEVELS.each { |risk_level|
      categories.each { |category|
        monitoree_counts.append(MonitoreeCount.new(
          active_monitoring: active_monitoring,
          category_type: category_type,
          category: category,
          risk_level: risk_level.nil? ? 'Missing' : risk_level,
          total: monitoree_count(monitorees, active_monitoring, risk_level, category_type, category)
        ))
      }
    }
    monitoree_counts
  end

  def monitoree_count(monitorees, active_monitoring, risk_level, category_type, category)
    monitorees.with_active_monitoring(active_monitoring)
              .with_risk_level(risk_level)
              .with_filter(category_type, category)
              .count
  end

  def last_exposure_dates
    (0..NUM_PAST_EXPOSURE_DAYS).map { |past_days| past_days.days.ago.to_date }
  end

  def last_exposure_weeks
    (0..NUM_PAST_EXPOSURE_WEEKS).map { |past_weeks| past_weeks.weeks.ago.at_beginning_of_week(start_day = :sunday).to_date }
  end

  def last_exposure_months
    (0..NUM_PAST_EXPOSURE_MONTHS).map { |past_months| past_months.months.ago.at_beginning_of_month.to_date }
  end
end
