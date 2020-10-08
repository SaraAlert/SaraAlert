# frozen_string_literal: true

FactoryBot.define do
  factory :jwt_identifier do
    value { 'MyString' }
    expiration_date { '2020-10-08 11:57:24' }
    oauth_applications { nil }
  end
end
