# frozen_string_literal: true

FactoryBot.define do
  factory :contact_attempt do
    patient { create(:patient) }
    user { create(:user) }
  end
end
