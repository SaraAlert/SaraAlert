# frozen_string_literal: true

FactoryBot.define do
  factory :reported_condition, parent: :condition, class: 'ReportedCondition' do
    type { 'ReportedCondition' }
    assessment { create(:assessment) }
    threshold_condition { create(:threshold_condition) }
  end
end
