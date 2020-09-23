# frozen_string_literal: true

# ReportedCondition
class ReportedCondition < Condition
  belongs_to :assessment
  belongs_to :threshold_condition

  scope :fever_or_fever_reducer, lambda {
    where_assoc_exists(:symptoms, &:fever_or_fever_reducer)
  }
end
