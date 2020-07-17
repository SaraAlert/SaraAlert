# frozen_string_literal: true

FactoryBot.define do
  factory :bool_symptom, parent: :symptom, class: 'BoolSymptom' do
    type { 'BoolSymptom' }
    bool_value { Faker::Boolean.boolean }

    factory :fever_reducer_symptom do
      name { 'used-a-fever-reducer' }
      bool_value { true }
    end

    factory :fever_symptom do
      name { 'fever' }
      bool_value { true }
    end
  end
end
