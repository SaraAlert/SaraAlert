# frozen_string_literal: true

FactoryBot.define do
  factory :laboratory do
    patient { create(:patient) }
  end
end
