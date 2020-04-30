# frozen_string_literal: true

FactoryBot.define do
  factory :jurisdiction do
    name { Faker::Address.city }

    after(:build) do |jurisdiction|
      jurisdiction.update(unique_identifier: Digest::SHA256.hexdigest(jurisdiction.jurisdiction_path_string))
    end

    factory :usa_jurisdiction do
      name { 'USA' }
    end

    factory :non_usa_jurisdiction do
      name { 'Unobtanium' }
    end
  end
end
