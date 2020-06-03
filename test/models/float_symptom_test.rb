# frozen_string_literal: true

require 'test_case'

class FloatSymptomTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  # ActiveRecord will automatically typecast Integers to Float so that's not tested here.
  test 'create float symptom' do
    string = 'v' * 200
    assert create(:float_symptom)
    assert create(:float_symptom, name: string, label: string, notes: string)
    # False is cast to 0.0
    assert create(:float_symptom, float_value: false)
    assert create(:float_symptom, float_value: Faker::Number.number).float_value.is_a?(Float)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:float_symptom, name: string << 'v')
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:float_symptom, notes: string)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:float_symptom, label: string)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:float_symptom, float_value: 'v')
    end

    # Build and update to work around after(:build) in symptom factory
    float_symptom = build(:float_symptom)
    float_symptom.float_value = nil
    assert float_symptom.save!

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:float_symptom, float_value: true)
    end
  end

  test 'get value' do
    symptom = create(:float_symptom)
    assert_equal symptom.float_value, symptom.value
  end

  test 'set value' do
    symptom = create(:float_symptom)
    symptom.value = 1.0
    assert_equal symptom.float_value, symptom.value
    assert_equal 1.0, symptom.value
    assert_equal 1.0, symptom.float_value
  end

  test 'float symptom as json' do
    symptom = create(:float_symptom)
    assert_includes symptom.to_json, 'float_value'
    assert_includes symptom.to_json, symptom.float_value.to_s
  end

  test 'float symptom bool based prompt' do
    symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Less Than', name: 'pulse-ox', label: 'Pulse Ox')
    assert_equal symptom.bool_based_prompt, 'Pulse ox less than 90.1'
    symptom.threshold_operator = 'Less Than Or Equal'
    assert_equal symptom.bool_based_prompt, 'Pulse ox less than or equal to 90.1'
    symptom.threshold_operator = 'Greater Than'
    assert_equal symptom.bool_based_prompt, 'Pulse ox greater than 90.1'
    symptom.threshold_operator = 'Greater Than Or Equal'
    assert_equal symptom.bool_based_prompt, 'Pulse ox greater than or equal to 90.1'
    symptom.threshold_operator = 'Equal'
    assert_equal symptom.bool_based_prompt, 'Pulse ox equal to 90.1'
    symptom.threshold_operator = 'Not Equal'
    assert_equal symptom.bool_based_prompt, 'Pulse ox not equal to 90.1'
  end

  test 'float symptom bool based prompt spanish' do
    symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Less Than', name: 'pulse-ox', label: 'Pulse Ox')
    assert_equal symptom.bool_based_prompt(:es), 'Oxímetro de pulso menos que 90.1'
    symptom.threshold_operator = 'Less Than Or Equal'
    assert_equal symptom.bool_based_prompt(:es), 'Oxímetro de pulso menor o igual a 90.1'
    symptom.threshold_operator = 'Greater Than'
    assert_equal symptom.bool_based_prompt(:es), 'Oxímetro de pulso mas grande que 90.1'
    symptom.threshold_operator = 'Greater Than Or Equal'
    assert_equal symptom.bool_based_prompt(:es), 'Oxímetro de pulso mayor que o igual a 90.1'
    symptom.threshold_operator = 'Equal'
    assert_equal symptom.bool_based_prompt(:es), 'Oxímetro de pulso igual a 90.1'
    symptom.threshold_operator = 'Not Equal'
    assert_equal symptom.bool_based_prompt(:es), 'Oxímetro de pulso no es igual a 90.1'
  end
end
