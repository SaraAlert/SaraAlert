# frozen_string_literal: true

FactoryBot.define do
  factory :vaccine do
    patient { create(:patient) }
    group_name { Vaccine.group_name_options.sample }
    product_name { Vaccine.product_name_options(group_name).sample }
  end
end
