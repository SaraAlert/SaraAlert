class AssociateReportedAndThresholdConditions < ActiveRecord::Migration[6.0]
  def change
    ReportedCondition.all.each do |rc|
      tc = ThresholdCondition.find_by(threshold_condition_hash: rc.threshold_condition_hash)
      rc.update!(threshold_condition_id: tc.id)
    end
  end
end
