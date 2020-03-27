class CreateAnalytics < ActiveRecord::Migration[6.0]
  def change
    create_table :analytics do |t|
      t.integer :jurisdiction_id

      t.integer :monitorees_count
      t.integer :symptomatic_monitorees_count
      t.integer :asymptomatic_monitorees_count
      t.integer :confirmed_cases_count
      t.integer :closed_cases_count
      t.integer :open_cases_count
      t.integer :total_reports_count
      t.integer :non_reporting_monitorees_count

      t.text :monitoree_state_map
      t.text :symptomatic_state_map

      t.timestamps
    end
  end
end
