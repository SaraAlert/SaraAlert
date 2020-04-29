# frozen_string_literal: true

FactoryBot.define do
  factory :monitoree_snapshot do
    analytic { create(:analytic) }
  end
end
