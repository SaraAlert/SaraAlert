# frozen_string_literal: true

FactoryBot.define do
  factory :user_filter do
    user { create(:user) }
    # rubocop:disable Layout/LineLength
    contents do
      [
        {
          'filterOption' => {
            'name' => 'vaccination',
            'title' => 'Vaccination (Combination)',
            'description' => 'Monitorees with specified Vaccination criteria',
            'type' => 'combination',
            'tooltip' => 'Returns records that contain at least one Vaccination entry that meets all user-specified criteria (e.g., searching for a specific Vaccination Product Name and Administration Date will only return records containing at least one Vaccination entry with matching values in both fields).',
            'fields' => [{
              'name' => 'vaccine-group',
              'title' => 'vaccine group',
              'type' => 'select',
              'options' => ['COVID-19']
            }, {
              'name' => 'product-name',
              'title' => 'product name',
              'type' => 'select',
              'options' => [
                'Moderna COVID-19 Vaccine (non-US Spikevax)',
                'Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)',
                'Janssen (J&J) COVID-19 Vaccine',
                'AstraZeneca COVID-19 Vaccine (Non-US tradenames include VAXZEVRIA, COVISHIELD)',
                'Coronavac (Sinovac) COVID-19 Vaccine',
                'Sinopharm (BIBP) COVID-19 Vaccine',
                'Unknown'
              ]
            }, {
              'name' => 'administration-date',
              'title' => 'administration date',
              'type' => 'date'
            }, {
              'name' => 'dose-number',
              'title' => 'dose number',
              'type' => 'select',
              'options' => ['', '1', '2', 'Unknown']
            }]
          },
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
    # rubocop:enable Layout/LineLength
    name { Faker::Alphanumeric.alphanumeric(number: 5) }
  end
end
