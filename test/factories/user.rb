# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password(min_length: 10, max_length: 20, mix_case: true) + '!' }
    jurisdiction { create(:jurisdiction) }

    transient do
      created_patients_count { 0 }
    end

    # Add suffix _user becuase the role conflicts namespaces and the role must be exact because the code depends on that
    # spelling.
    factory :admin_user do
      after(:create) do |user|
        user.add_role(:admin)
      end
    end

    factory :enroller_user do
      after(:create) do |user|
        user.add_role(:enroller)
      end
    end

    factory :public_health_enroller_user do
      after(:create) do |user|
        user.add_role(:public_health_enroller)
      end
    end

    factory :public_health_user do
      after(:create) do |user|
        user.add_role(:public_health)
      end
    end

    factory :analyst_user do
      after(:create) do |user|
        user.add_role(:analyst)
      end
    end

    after(:create) do |user, evaluator|
      evaluator.created_patients_count.times do
        user.created_patients << create(:patient, creator: user, jurisdiction: user.jurisdiction)
      end
    end
  end
end
