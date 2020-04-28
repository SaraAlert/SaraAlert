# frozen_string_literal: true

FactoryBot.define do
  factory :float_symptom, parent: :symptom, class: 'FloatSymptom' do
    type { 'FloatSymptom' }
    float_value { Faker::Number.decimal }
  end
end
