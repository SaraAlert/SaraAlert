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

    assert_raises(ActiveRecord::RecordInvalid) do
      # Build and update to work around after(:build) in symptom factory
      float_symptom = build(:float_symptom)
      float_symptom.float_value = nil
      float_symptom.save!
    end

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
end
