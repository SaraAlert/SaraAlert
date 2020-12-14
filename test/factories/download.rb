# frozen_string_literal: true

FactoryBot.define do
  factory :download do
    user_id { create(:user).id }
    lookup { SecureRandom.uuid }
    filename { Faker::Alphanumeric.alphanumeric(number: 5) }
    export_type { %w[csv_linelist_isolation csv_linelist_exposure].sample }
    contents { Faker::Alphanumeric.alphanumeric(number: 100) }
  end
end
