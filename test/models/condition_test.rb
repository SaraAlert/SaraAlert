# frozen_string_literal: true

require 'test_case'
require_relative '../test_helpers/symptom_test_helper'

class ConditionTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create condition' do
    assert create(:condition)
    assert create(:condition, symptoms_count: Faker::Number.between(from: 1, to: 5))
  end

  test 'build symptoms' do
    symptoms_array = []
    Faker::Number.between(from: 1, to: 5).times do
      temp_symptom = build(:symptom)
      symptoms_array.push(SymptomTestHelper.create_symptom_as_hash(
                            kname: Faker::Alphanumeric.alpha,
                            value: SymptomTestHelper.get_value(temp_symptom),
                            type: temp_symptom.type,
                            label: Faker::Alphanumeric.alpha,
                            notes: Faker::Alphanumeric.alpha
                          ))
    end
    typed_symptoms = ::Condition.build_symptoms(symptoms_array)
    symptoms_array.each_with_index do |symptom, idx|
      symptom.each_key do |key|
        assert_equal(typed_symptoms[idx].send(key), symptom[key])
      end
    end

    assert_equal([], ::Condition.build_symptoms([]))

    assert_raises(TypeError) do
      ::Condition.build_symptoms(SymptomTestHelper.create_symptom_as_hash)
    end

    assert_raises(ArgumentError) do
      ::Condition.build_symptoms(['v'])
    end

    symptoms_array = []
    temp_symptom = build(:symptom)
    symptoms_array.push(SymptomTestHelper.create_symptom_as_hash(
                          kname: Faker::Alphanumeric.alpha,
                          value: SymptomTestHelper.get_value(temp_symptom),
                          type: temp_symptom.type,
                          label: Faker::Alphanumeric.alpha,
                          notes: Faker::Alphanumeric.alpha
                        ))
    symptoms_array.push(SymptomTestHelper.create_symptom_as_hash(
                          kname: Faker::Alphanumeric.alpha,
                          value: SymptomTestHelper.get_value(temp_symptom),
                          type: 'Invalid',
                          label: Faker::Alphanumeric.alpha,
                          notes: Faker::Alphanumeric.alpha
                        ))
    typed_symptoms = ::Condition.build_symptoms(symptoms_array)
    assert_equal 1, typed_symptoms.length
    symptoms_array.first.each_key do |key|
      assert_equal(typed_symptoms.first.send(key), symptoms_array.first[key])
    end
  end
end
