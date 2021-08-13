# frozen_string_literal: true

module UserFiltersTestHelper
  def self.combination_filter_params
    {
      'activeFilterOptions' => [{
        'filterOption' => {
          'name' => 'lab-result',
          'title' => 'Lab Result (Combination)',
          'description' => 'Monitorees with specified Lab Result criteria',
          'type' => 'combination',
          'tooltip' => 'short tooltip',
          'fields' => [{
            'name' => 'result',
            'title' => 'result',
            'type' => 'select',
            'options' => ['positive', 'negative', 'indeterminate', 'other', '']
          }]
        },
        'value' => [{
          'name' => 'result',
          'value' => 'positive'
        }],
        'numberOption' => nil,
        'dateOption' => nil,
        'relativeOption' => nil,
        'additionalFilterOption' => nil
      }],
      'name' => 'Test'
    }
  end

  def self.multi_select_filter_params(options_selected:)
    raise(ArgumentError, 'options_selected must be false, alternative is not implemented') if options_selected

    # Value and all options are nil.
    {
      'activeFilterOptions' => [{
        'filterOption' => {
          'name' => 'assigned-user',
          'title' => 'Assigned User (Multi-select)',
          'description' => 'Monitorees who have a specific assigned user',
          'type' => 'multi',
          'options' => [{ 'value' => 57, 'label' => 57 }]
        },
        'value' => [],
        'numberOption' => nil,
        'dateOption' => nil,
        'relativeOption' => nil,
        'additionalFilterOption' => nil
      }],
      'name' => 'Test'
    }
  end
end
