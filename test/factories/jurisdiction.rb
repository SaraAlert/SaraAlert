# frozen_string_literal: true

FactoryBot.define do
  factory :jurisdiction do
    name { Faker::Address.city }
    path { name }

    after(:build) do |jurisdiction|
      jurisdiction.update(unique_identifier: Digest::SHA256.hexdigest(jurisdiction[:path]))
      jurisdiction.update(threshold_conditions: [create(:threshold_condition, symptoms_count: 1)])
    end

    factory :usa_jurisdiction do
      name { 'USA' }
    end

    factory :non_usa_jurisdiction do
      name { 'Unobtanium' }
    end
  end
end
