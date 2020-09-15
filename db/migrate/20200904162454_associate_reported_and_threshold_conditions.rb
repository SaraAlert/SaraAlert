class AssociateReportedAndThresholdConditions < ActiveRecord::Migration[6.0]
  def change
    threshold_conditions = ThresholdCondition.all.map {|tc| [tc.threshold_condition_hash, tc.id]}.to_h
    ReportedCondition.all.each do |rc|
      rc.update!(threshold_condition_id: threshold_conditions[rc.threshold_condition_hash])
    end
  end
end
