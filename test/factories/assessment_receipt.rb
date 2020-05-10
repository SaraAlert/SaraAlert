# frozen_string_literal: true

FactoryBot.define do
  factory :assessment_receipt do
    submission_token { Faker::Alphanumeric.alphanumeric(number: 40) }
  end
end
