# frozen_string_literal: true

# ReportedCondition
class ReportedCondition < Condition
  belongs_to :assessment

  def threshold_condition
    # Because threshold_condition_hash is calculated based on jurisdiction_path and edit_count
    # there should never be multiple threshold_condition_hash with the same non-nil value.
    # If there is a collision the threshold condition was created for the same jurisdiction at the
    # same time at the edit history
    ThresholdCondition.find_by(threshold_condition_hash: threshold_condition_hash)
  end

  scope :fever_or_fever_reducer, lambda {
    where_assoc_exists(:symptoms, &:fever_or_fever_reducer)
  }
end
