# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    # Guarantee an upper, lower, and symbol
    password { Faker::Internet.password(min_length: 10, max_length: 125, mix_case: true, special_characters: true) + 'aB!' }
    jurisdiction { create(:jurisdiction) }
    authy_enabled { false }
    authy_enforced { false }
    role { 'none' }

    transient do
      created_patients_count { 0 }
    end

    # Add suffix _user because the role conflicts namespaces and the role must be exact because the code depends on that
    # spelling.
    factory :admin_user do
      role { 'admin' }
    end

    factory :usa_admin_user do
      jurisdiction { create(:usa_jurisdiction) }
      role { 'admin' }
    end

    factory :non_usa_admin_user do
      jurisdiction { create(:non_usa_jurisdiction) }
      role { 'admin' }
    end

    factory :enroller_user do
      role { 'enroller' }
    end

    factory :public_health_enroller_user do
      role { 'public_health_enroller' }
    end

    factory :public_health_user do
      role { 'public_health' }
    end

    factory :analyst_user do
      role { 'analyst' }
    end

    factory :super_user do
      role { 'super_user' }
    end

    factory :usa_super_user do
      jurisdiction { create(:usa_jurisdiction) }
      role { 'super_user' }
    end

    factory :non_usa_super_user do
      jurisdiction { create(:non_usa_jurisdiction) }
      role { 'super_user' }
    end

    factory :contact_tracer_user do
      role { 'contact_tracer' }
    end

    after(:create) do |user, evaluator|
      evaluator.created_patients_count.times do
        user.created_patients << create(:patient, creator: user, jurisdiction: user.jurisdiction)
      end
    end
  end
end
