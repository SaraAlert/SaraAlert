# frozen_string_literal: true

FactoryBot.define do
  factory :monitoree_count do
    analytic { create(:analytic) }
  end
end
