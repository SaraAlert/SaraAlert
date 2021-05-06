# frozen_string_literal: true

FactoryBot.define do
  factory :download do
    user_id { create(:user).id }
    filename { Faker::Alphanumeric.alphanumeric(number: 5) }
    export_type { %w[csv_linelist_isolation csv_linelist_exposure].sample }
  end
end
