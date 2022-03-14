# frozen_string_literal: true

FactoryBot.define do
  factory :user_filter do
    user { create(:user) }
    contents do
      [
        {
          'name' => 'vaccination',
          'type' => 'combination',
          'value' => [{
            'name' => 'vaccine-group',
            'value' => 'COVID-19'
          }, {
            'name' => 'product-name',
            'value' => 'Janssen (J&J) COVID-19 Vaccine'
          }],
          'numberOption' => nil,
          'dateOption' => nil,
          'relativeOption' => nil,
          'additionalFilterOption' => nil
        }
      ].to_json
    end
    name { Faker::Alphanumeric.alphanumeric(number: 5) }
  end
end
