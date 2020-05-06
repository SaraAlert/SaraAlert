# frozen_string_literal: true

# Condition
class Condition < ApplicationRecord
  has_many :symptoms

  def self.build_symptoms(symptoms_array)
    raise TypeError, "no conversion of #{symptoms_array.class} to Symptoms Array" unless symptoms_array.is_a?(Array)

    typed_symptoms = []

    symptoms_array.each do |symp|
      symptom = Symptom.new(symp)
      typed_symptoms.push(symptom)
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error("Attempting to create Symptom with `#{symp}` caused the following: #{e}")
      next
    end
    typed_symptoms
  end
end
