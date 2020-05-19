# frozen_string_literal: true

FactoryBot.define do
  factory :assessment do
    patient { create(:patient) }
  end
end
