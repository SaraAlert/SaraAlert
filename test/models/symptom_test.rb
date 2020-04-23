# frozen_string_literal: true

require 'test_helper'

class SymptomTest < ActiveSupport::TestCase
  test 'Symptom validation does not allow string fields to exceed 200 characters' do
    str_just_long_enough = '0' * 200
    str_too_long = '0' * 201

    test_symptom = FloatSymptom.new(name: str_just_long_enough, label: str_just_long_enough, float_value: 12.1)
    # No string length violations, should save without error
    assert test_symptom.save!

    test_symptom = FloatSymptom.new(name: str_too_long, label: str_too_long, float_value: 12.1)
    # String length too long for name and label, should throw exception
    exception = assert_raises(Exception) { test_symptom.save! }
    assert_equal('Validation failed: Name is too long (maximum is 200 characters), Label is too long (maximum is 200 characters)', exception.message)

    test_symptom = IntegerSymptom.new(name: str_just_long_enough, label: str_just_long_enough, int_value: 12)
    # No string length violations, should save without error
    assert test_symptom.save!

    test_symptom = IntegerSymptom.new(name: str_too_long, label: str_too_long, int_value: 12)
    # String length too long for name and label, should throw exception
    exception = assert_raises(Exception) { test_symptom.save! }
    assert_equal('Validation failed: Name is too long (maximum is 200 characters), Label is too long (maximum is 200 characters)', exception.message)

    test_symptom = BoolSymptom.new(name: str_just_long_enough, label: str_just_long_enough, bool_value: true)
    # No string length violations, should save without error
    assert test_symptom.save!

    test_symptom = BoolSymptom.new(name: str_too_long, label: str_too_long, bool_value: true)
    # String length too long for name and label, should throw exception
    exception = assert_raises(Exception) { test_symptom.save! }
    assert_equal('Validation failed: Name is too long (maximum is 200 characters), Label is too long (maximum is 200 characters)', exception.message)
  end
end
