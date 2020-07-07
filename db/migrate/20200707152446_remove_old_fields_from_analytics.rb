class RemoveOldFieldsFromAnalytics < ActiveRecord::Migration[6.0]
  def change
    remove_column :analytics, :monitorees_count
    remove_column :analytics, :symptomatic_monitorees_count
    remove_column :analytics, :asymptomatic_monitorees_count
    remove_column :analytics, :confirmed_cases_count
    remove_column :analytics, :closed_cases_count
    remove_column :analytics, :open_cases_count
    remove_column :analytics, :total_reports_count
    remove_column :analytics, :non_reporting_monitorees_count
    remove_column :analytics, :monitoree_state_map
    remove_column :analytics, :symptomatic_state_map
  end
end
