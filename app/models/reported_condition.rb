class ReportedCondition < Condition
    def get_threshold_condition
        return ThresholdCondition.where(threshold_condition_hash: threshold_condition_hash).first
    end
end
