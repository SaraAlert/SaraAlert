# frozen_string_literal: true

FactoryBot.define do
  factory :threshold_condition, parent: :condition, class: 'ThresholdCondition' do
    type { 'ThresholdCondition' }
  end
end
