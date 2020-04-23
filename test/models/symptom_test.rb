# frozen_string_literal: true

require 'test_helper'

class SymptomTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create symptom' do

    Symptom.valid_types.each do |type|
      string = 'v' * 200
      # No string fields
      assert create(:symptom, type: type)
      # Valid string fields
      assert create(:symptom, type: type, name: string)
      assert create(:symptom, type: type, label: string)
      assert create(:symptom, type: type, notes: string)

      string << 'v'
      # Invalid string fields (length too long)
      assert_raises(ActiveRecord::RecordInvalid) do
        create(:symptom, type: type, name: string)
      end

      assert_raises(ActiveRecord::RecordInvalid) do
        create(:symptom, type: type, label: string)
      end

      assert_raises(ActiveRecord::RecordInvalid) do
        create(:symptom, type: type, notes: string)
      end
    end
    # Invalid type field
    assert_raises(ActiveRecord::RecordInvalid) do
      create(:symptom, type: 'Invalid')
    end
  end

  test 'fever' do
    assert_difference('Symptom.fever.size', 1) do
      create(:bool_symptom, bool_value: true, name: 'fever')
    end

    assert_no_difference('Symptom.fever.size') do
      create(:bool_symptom, bool_value: false, name: 'fever')
      create(:bool_symptom, bool_value: true, name: 'not fever')
    end
  end

  test 'symptom as json' do
    Symptom.valid_types.each do |type|
      symptom = create(:symptom, type: type)
      assert_includes symptom.to_json, 'type'
      assert_includes symptom.to_json, symptom.type.to_s
    end
  end
end
