# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    # Guarantee an upper, lower, and symbol
    password { Faker::Internet.password(min_length: 10, max_length: 125, mix_case: true, special_characters: true) + 'aB!' }
    jurisdiction { create(:jurisdiction) }
    authy_enabled { false }
    authy_enforced { false }

    transient do
      created_patients_count { 0 }
    end

    # Add suffix _user becuase the role conflicts namespaces and the role must be exact because the code depends on that
    # spelling.
    factory :admin_user do
      after(:create) do |user|
        user.update(role: 'admin')
      end
    end

    factory :usa_admin_user do
      jurisdiction { create(:usa_jurisdiction) }
      after(:create) do |user|
        user.update(role: 'admin')
      end
    end

    factory :non_usa_admin_user do
      jurisdiction { create(:non_usa_jurisdiction) }
      after(:create) do |user|
        user.update(role: 'admin')
      end
    end

    factory :enroller_user do
      after(:create) do |user|
        user.update(role: 'enroller')
      end
    end

    factory :public_health_enroller_user do
      after(:create) do |user|
        user.update(role: 'public_health_enroller')
      end
    end

    factory :public_health_user do
      after(:create) do |user|
        user.update(role: 'public_health')
      end
    end

    factory :analyst_user do
      after(:create) do |user|
        user.update(role: 'analyst')
      end
    end

    after(:create) do |user, evaluator|
      evaluator.created_patients_count.times do
        user.created_patients << create(:patient, creator: user, jurisdiction: user.jurisdiction)
      end
    end
  end
end
