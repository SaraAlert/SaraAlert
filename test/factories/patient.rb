# frozen_string_literal: true

FactoryBot.define do
  factory :patient do
    creator { create(:user) }
    after(:build) do |patient|
      patient.update(jurisdiction: patient.creator.jurisdiction)
      patient.update(responder: patient)
    end
  end
end
