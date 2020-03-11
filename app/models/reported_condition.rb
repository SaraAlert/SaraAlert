# frozen_string_literal: true

# ReportedCondition
class ReportedCondition < Condition
  def threshold_condition
    ThresholdCondition.where(threshold_condition_hash: threshold_condition_hash).first
  end
end
