# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    factory :enroller do
      name { :enroller }
    end
    factory :public_health do
      name { :public_health }
    end
    factory :public_health_enroller do
      name { :public_health_enroller }
    end
    factory :admin do
      name { :admin }
    end
    factory :analyst do
      name { :analyst }
    end
  end
end
