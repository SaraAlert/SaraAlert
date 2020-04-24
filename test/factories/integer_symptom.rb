# frozen_string_literal: true

FactoryBot.define do
  factory :integer_symptom, parent: :symptom, class: 'IntegerSymptom' do
    type { 'IntegerSymptom' }
    int_value { Faker::Number.between(from: 0, to: 2_147_483_648) }
  end
end
