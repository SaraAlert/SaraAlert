# frozen_string_literal: true

module UserFiltersTestHelper
  def self.combination_filter_params
    {
      'activeFilterOptions' => [{
        'name' => 'lab-result',
        'type' => 'combination',
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

  def self.multi_select_filter_params
    {
      'activeFilterOptions' => [{
        'name' => 'assigned-user',
        'type' => 'multi',
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
