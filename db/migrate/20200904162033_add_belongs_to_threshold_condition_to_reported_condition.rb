class AddBelongsToThresholdConditionToReportedCondition < ActiveRecord::Migration[6.0]
  def change
    add_column :conditions, :threshold_condition_id, :integer
  end
end
