# frozen_string_literal: true

# ThresholdCondition
class ThresholdCondition < Condition
  # When someone answers that they are 'experiencing symptoms' and does not
  # fill out a complete report, we use this function to generate a list of
  # symptoms with nil values to build a ReportedCondition with nil values
  # flagging the monitoree for manual follow-up.
  def clone_symptoms_remove_values
    new_symptoms = symptoms.to_a.deep_dup
    new_symptoms.each { |s| s.value = nil }
  end

  # When someone answers that they are 'not experiencing symptoms' and does not
  # fill out a complete report, we use this function to generated list of
  # symptoms with false boolean values so that the monitoree is not flagged for
  # manual follow-up.
  def clone_symptoms_negate_bool_values
    new_symptoms = symptoms.to_a.deep_dup
    new_symptoms.each { |s| s.value = 0 }
  end
end
