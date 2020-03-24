# frozen_string_literal: true

# ThresholdCondition
class ThresholdCondition < Condition
  def clone_symptoms_remove_values
    new_symptoms = []
    self.symptoms.each do |symptom|
      new_symptom = symptom.dup
      new_symptom.value = nil
      new_symptoms.push(new_symptom)
    end
    return new_symptoms
  end

  def clone_symptoms_negate_bool_values
    new_symptoms = []
    self.symptoms.each do |symptom|
      new_symptom = symptom.dup
      if symptom.type == "BoolSymptom"
        new_symptom.value = !symptom.value
      else
        new_symptom.value = 0
      end
      new_symptoms.push(new_symptom)
    end
    return new_symptoms
  end
end
