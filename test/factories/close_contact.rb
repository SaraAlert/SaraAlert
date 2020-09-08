# frozen_string_literal: true

FactoryBot.define do
  factory :close_contact do
    patient_id { create(:patient) }
  end
end
