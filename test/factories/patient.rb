# frozen_string_literal: true

FactoryBot.define do
  factory :patient do
    creator { create(:user) }
    after(:build) do |patient|
      update_hash = { jurisdiction: patient.creator.jurisdiction }
      update_hash[:responder] = patient if patient.responder.nil?
      patient.update(update_hash)
    end

    factory :patient_with_submission_token do
      submission_token { SecureRandom.urlsafe_base64[0, 10] }
    end
  end
end
