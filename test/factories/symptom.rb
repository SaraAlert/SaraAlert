# frozen_string_literal: true

FactoryBot.define do
  factory :symptom do
    type { Symptom.valid_types.sample }
    name { Faker::Alphanumeric.alphanumeric(number: 10) }
    label { Faker::Alphanumeric.alphanumeric(number: 10) }
    notes { Faker::Alphanumeric.alphanumeric(number: 10) }

    initialize_with { type.constantize.new }

    after(:build) do |symptom|
      if symptom.type == 'IntegerSymptom' && symptom.int_value.nil?
        symptom.int_value = Faker::Number.between(from: 0, to: 2_147_483_648)
      elsif symptom.type == 'BoolSymptom' && symptom.bool_value.nil?
        symptom.bool_value = false
      elsif symptom.type == 'FloatSymptom' && symptom.float_value.nil?
        symptom.float_value = Faker::Number.decimal
      end
    end
  end
end
