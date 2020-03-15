namespace :analytics do

  desc "Cache Current Analytics"
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
    analytic.closed_cases_count = jurisdiction_monitorees.monitoring_closed.count
    analytic.open_cases_count = jurisdiction_monitorees.monitoring_open.count
    analytic.non_reporting_monitorees_count = jurisdiction_monitorees.non_reporting.count
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
end
