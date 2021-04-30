# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_application do
    name { Faker::Alphanumeric.alphanumeric(number: 5) }
    redirect_uri { 'urn:ietf:wg:oauth:2.0:oob' }
  end
end
