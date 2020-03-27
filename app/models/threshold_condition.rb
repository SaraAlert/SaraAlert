# frozen_string_literal: true

# ThresholdCondition
class ThresholdCondition < Condition
  def clone_symptoms_remove_values
    new_symptoms = []
    symptoms.each do |symptom|
      new_symptom = symptom.dup
      new_symptom.value = nil
      new_symptoms.push(new_symptom)
    end
    new_symptoms
  end

  def clone_symptoms_negate_bool_values
    new_symptoms = []
    symptoms.each do |symptom|
      new_symptom = symptom.dup
      new_symptom.value = if symptom.type == 'BoolSymptom'
                            !symptom.value
                          else
                            0
                          end
      new_symptoms.push(new_symptom)
    end
    new_symptoms
  end
end
