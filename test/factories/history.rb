# frozen_string_literal: true

FactoryBot.define do
  factory :history do
    patient { create(:patient) }
    history_type { History::HISTORY_TYPES[:comment] }
  end
end
