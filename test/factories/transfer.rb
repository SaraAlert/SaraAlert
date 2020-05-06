# frozen_string_literal: true

FactoryBot.define do
  factory :transfer do
    patient { create(:patient) }
    to_jurisdiction { create(:jurisdiction) }

    after(:build) do |transfer|
      transfer.update(who: transfer.patient.creator)
      transfer.update(from_jurisdiction: transfer.patient.jurisdiction)
    end
  end
end
