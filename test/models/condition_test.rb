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
  end
end
