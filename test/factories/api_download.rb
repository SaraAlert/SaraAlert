# frozen_string_literal: true

FactoryBot.define do
  factory :api_download do
    application_id { create(:oauth_application).id }
    job_id { Faker::Alphanumeric.alphanumeric(number: 5) }
  end
end
