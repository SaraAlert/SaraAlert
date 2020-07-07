class RemoveSymptomaticStateMapFromAnalytics < ActiveRecord::Migration[6.0]
  def change
    remove_column :analytics, :symptomatic_state_map
  end
end
