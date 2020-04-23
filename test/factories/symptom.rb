# frozen_string_literal: true

FactoryBot.define do
  factory :symptom do
    type { Symptom.valid_types.select }

    after(:build) do |symptom|
      case symptom.type
      when 'IntegerSymptom'
        symptom.int_value = symptom.int_value || Faker::Number.between(from: 1, to: 2_147_483_648)
      when 'BoolSymptom'
        if symptom.bool_value.nil?
          symptom.bool_value = Faker::Boolean.boolean
        end
      when 'FloatSymptom'
        symptom.float_value = symptom.float_value || Faker::Number.decimal
      end
    end
  end
end
