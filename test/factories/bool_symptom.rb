# frozen_string_literal: true

FactoryBot.define do
  factory :bool_symptom, parent: :symptom, class: 'BoolSymptom' do
    type { 'BoolSymptom' }
    bool_value { Faker::Boolean.boolean }
  end
end
