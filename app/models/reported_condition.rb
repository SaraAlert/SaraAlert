# frozen_string_literal: true

# ReportedCondition
class ReportedCondition < Condition
  def threshold_condition
    ThresholdCondition.where(threshold_condition_hash: threshold_condition_hash).first
  end

  scope :fever_medication, lambda {
    where_assoc_exists(:symptoms, &:fever_medication)
  }

  scope :fever, lambda {
    where_assoc_not_exists(:symptoms, &:fever_medication)
      .where_assoc_exists(:symptoms, &:fever)
  }
end
