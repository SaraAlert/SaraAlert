# frozen_string_literal: true

FactoryBot.define do
  factory :history do
    patient { create(:patient) }
  end
end
