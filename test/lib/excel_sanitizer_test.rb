# frozen_string_literal: true

require 'test_case'

class ExcelSanitizerTest < ActiveSupport::TestCase
  include ExcelSanitizer

  test 'removes = from beginning of string' do
    assert_equal(remove_formula_start(' =test'), ' =test')
    assert_equal(remove_formula_start('=test'), 'test')
    assert_equal(remove_formula_start('==test'), 'test')
    assert_equal(remove_formula_start('=='), '')
    assert_equal(remove_formula_start('= ='), ' =')
    assert_equal(remove_formula_start('= =='), '')
    assert_equal(remove_formula_start(''), '')
    assert_nil(remove_formula_start(nil))
  end
end
