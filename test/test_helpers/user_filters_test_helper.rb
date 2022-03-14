# frozen_string_literal: true

module UserFiltersTestHelper
  def self.combination_filter_params
    {
      'activeFilterOptions' => [{
        'name' => 'lab-result',
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
        'name' => 'assigned-user',
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
