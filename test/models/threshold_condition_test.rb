# frozen_string_literal: true

require 'test_case'

class ThresholdConditionTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create threshold condition' do
    assert create(:threshold_condition)
    assert create(:threshold_condition, threshold_condition_hash: Faker::Alphanumeric.alphanumeric(number: 64))
    assert create(:threshold_condition, jurisdiction_id: create(:jurisdiction).id)
  end

  test 'clone symptoms remove values' do
    threshold_condition = create(:threshold_condition, symptoms_count: 5)
    symptoms = threshold_condition.clone_symptoms_remove_values

    symptoms.each_with_index do |symptom, idx|
      assert_nil(symptom.value)
      assert_equal(threshold_condition.symptoms[idx].name, symptom.name)
      assert_equal(threshold_condition.symptoms[idx].label, symptom.label)
      assert_equal(threshold_condition.symptoms[idx].notes, symptom.notes)
    end
  end

  test 'clone symptoms negate bool values' do
    threshold_condition = create(:threshold_condition, symptoms_count: 5)
    symptoms = threshold_condition.clone_symptoms_negate_bool_values

    symptoms.each_with_index do |symptom, idx|
      if symptom.type == 'BoolSymptom'
        assert_not_equal(threshold_condition.symptoms[idx].value, symptom.value)
      else
        assert_equal(0, symptom.value)
      end
      assert_equal(threshold_condition.symptoms[idx].name, symptom.name)
      assert_equal(threshold_condition.symptoms[idx].label, symptom.label)
      assert_equal(threshold_condition.symptoms[idx].notes, symptom.notes)
    end
  end
end
