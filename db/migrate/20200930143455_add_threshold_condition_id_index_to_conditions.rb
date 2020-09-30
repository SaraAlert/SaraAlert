class AddThresholdConditionIdIndexToConditions < ActiveRecord::Migration[6.0]
  def change
    add_index :conditions, :threshold_condition_id
  end
end
