# frozen_string_literal: true

FactoryBot.define do
  factory :patient do
    creator { create(:user) }
    after(:build) do |patient|
      update_hash = { jurisdiction: patient.creator.jurisdiction }
      update_hash[:responder] = patient if patient.responder.nil?
      patient.update(update_hash)
    end
  end
end
