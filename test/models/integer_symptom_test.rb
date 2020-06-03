# frozen_string_literal: true

require 'test_case'

class IntegerSymptomTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create integer symptom' do
    string = 'v' * 200
    assert create(:integer_symptom)
    assert create(:integer_symptom, name: string, label: string, notes: string)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:integer_symptom, name: string << 'v')
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:integer_symptom, notes: string)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:integer_symptom, label: string)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:integer_symptom, int_value: 'v')
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:integer_symptom, int_value: ActiveModel::Type::Integer.new.send(:max_value) + 1)
    end

    symptom = build(:integer_symptom)
    symptom.int_value = nil
    assert symptom.save!
  end

  test 'get value' do
    symptom = create(:integer_symptom)
    assert_equal symptom.int_value, symptom.value
  end

  test 'set value' do
    symptom = create(:integer_symptom)
    symptom.value = 1
    assert_equal symptom.int_value, symptom.value
    assert_equal 1, symptom.value
    assert_equal 1, symptom.int_value
  end

  test 'integer symptom as json' do
    symptom = create(:integer_symptom)
    assert_includes symptom.to_json, 'int_value'
    assert_includes symptom.to_json, symptom.int_value.to_s
  end

  test 'integer symptom bool based prompt' do
    symptom = create(:integer_symptom, int_value: 90, threshold_operator: 'Less Than', name: 'pulse-ox', label: 'Pulse Ox')
    assert_equal symptom.bool_based_prompt, 'Pulse ox less than 90'
    symptom.threshold_operator = 'Less Than Or Equal'
    assert_equal symptom.bool_based_prompt, 'Pulse ox less than or equal to 90'
    symptom.threshold_operator = 'Greater Than'
    assert_equal symptom.bool_based_prompt, 'Pulse ox greater than 90'
    symptom.threshold_operator = 'Greater Than Or Equal'
    assert_equal symptom.bool_based_prompt, 'Pulse ox greater than or equal to 90'
    symptom.threshold_operator = 'Equal'
    assert_equal symptom.bool_based_prompt, 'Pulse ox equal to 90'
    symptom.threshold_operator = 'Not Equal'
    assert_equal symptom.bool_based_prompt, 'Pulse ox not equal to 90'
  end
end
