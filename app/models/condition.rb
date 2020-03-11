# frozen_string_literal: true

# Condition
class Condition < ApplicationRecord
  has_many :symptoms

  def self.build_symptoms(symptoms_array)
    typed_symptoms = []

    symptoms_array.each do |symp|
      symptom = Symptom.new(symp)
      typed_symptoms.push(symptom)
    end
    typed_symptoms
  end
end
