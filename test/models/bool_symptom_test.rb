# frozen_string_literal: true

require 'test_case'

class BoolSymptomTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  # ActiveRecord will automatically typecast most types to Boolean so that's not tested here.
  test 'create bool symptoms' do
    string = 'v' * 200
    assert create(:bool_symptom)
    assert create(:bool_symptom, name: string, label: string, notes: string)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:bool_symptom, name: string << 'v')
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:bool_symptom, notes: string)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:bool_symptom, label: string)
    end

    symptom = build(:bool_symptom)
    symptom.bool_value = nil
    assert symptom.save!
  end

  test 'get value' do
    symptom = create(:bool_symptom)
    assert_equal symptom.bool_value, symptom.value
  end

  test 'set value' do
    symptom = create(:bool_symptom)
    old_value = !symptom.value
    assert_not_equal symptom.value, old_value
    assert_equal symptom.value, symptom.bool_value
  end

  test 'bool symptom as json' do
    symptom = create(:bool_symptom)
    assert_includes symptom.to_json, 'bool_value'
    assert_includes symptom.to_json, symptom.bool_value.to_s
  end

  test 'bool symptom bool based prompt' do
    symptom = create(:bool_symptom, bool_value: true, name: 'fever', label: 'Fever')
    assert_equal symptom.bool_based_prompt, 'Fever'
  end
end
