# frozen_string_literal: true

require 'test_case'
require_relative '../test_helpers/symptom_test_helper'

class AssessmentTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'float symptom less than passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Less Than', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:float_symptom, float_value: 90.0, threshold_operator: 'Less Than', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 90.0 is less than 90.1
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90.1 is not less than 90.1
    reported_symptom.value = 90.1
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is not less than 90.1
    reported_symptom.value = 91
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'float symptom less than or equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Less Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:float_symptom, float_value: 90.0, threshold_operator: 'Less Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 90.0 is less than or equal 90.1
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90.1 is less than or equal 90.1
    reported_symptom.value = 90.1
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is not less than or equal 90.1
    reported_symptom.value = 91
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'float symptom greater than passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Greater Than', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:float_symptom, float_value: 91.0, threshold_operator: 'Greater Than', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 91.0 is greater than 90.1
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90.1 is not greater than 90.1
    reported_symptom.value = 90.1
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not less than 90.1
    reported_symptom.value = 90
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'float symptom greater than or equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:float_symptom, float_value: 91.0, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 91.0 is greater than or equal 90.1
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90.1 is greater than or equal 90.1
    reported_symptom.value = 90.1
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not greater than or equal 90.1
    reported_symptom.value = 90
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'float symptom equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 90.1 is equal to 90.1
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91.1 is not equal to 90.1
    reported_symptom.value = 91.1
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'float symptom not equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Not Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:float_symptom, float_value: 90.1, threshold_operator: 'Not Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 90.1 is not not equal to 90.1
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91.1 is not equal to 90.1
    reported_symptom.value = 91.1
    assert assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'integer symptom less than passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Less Than', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:integer_symptom, int_value: 90, threshold_operator: 'Less Than', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 90 is less than 91
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is not less than 91
    reported_symptom.value = 91
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is not less than 91
    reported_symptom.value = 91
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'integer symptom less than or equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Less Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:integer_symptom, int_value: 90, threshold_operator: 'Less Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 90 is less than or equal 91
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is less than or equal 91
    reported_symptom.value = 91
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 92 is not less than or equal 91
    reported_symptom.value = 92
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'integer symptom greater than passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Greater Than', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:integer_symptom, int_value: 92, threshold_operator: 'Greater Than', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 92 is greater than 91
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is not greater than 91
    reported_symptom.value = 91
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not less than 91
    reported_symptom.value = 90
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'integer symptom greater than or equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 91 is greater than or equal 91
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is greater than or equal 91
    reported_symptom.value = 91
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not greater than or equal 91
    reported_symptom.value = 90
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'integer symptom equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 91 is equal to 91
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not equal to 91
    reported_symptom.value = 90
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'integer symptom not equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Not Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Not Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert 91 is not not equal to 91
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not equal to 91
    reported_symptom.value = 90
    assert assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'bool symptom equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert true is equal to true
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert true is not equal to false
    reported_symptom.value = false
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'bool symptom not equal passes threshold' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:bool_symptom, bool_value: true, threshold_operator: 'Not Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:bool_symptom, bool_value: false, threshold_operator: 'Not Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert false is not equal to true
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert true is not equal to true
    reported_symptom.value = true
    assert_not assessment.symptom_passes_threshold('pulse-ox')
  end

  test 'symptomatic when symptom groups specified' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom_1 = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox', group: 2)
    threshold_symptom_2 = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'fever', label: 'Fever', group: 2)
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom_1, threshold_symptom_2])
    reported_symptom_1 = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_symptom_2 = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'fever', label: 'Fever')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom_1, reported_symptom_2], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert symptomatic when 2/2 group 2 symptoms pass threshold
    assert assessment.symptomatic?
    # Assert non_symptomatic when 1/2 group 2 symptoms pass threshold
    reported_symptom_2.value = false
    assert_not assessment.symptomatic?
  end

  test 'symptomatic when group defaults to group 1' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom_1 = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox')
    threshold_symptom_2 = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'fever', label: 'Fever', group: 2)
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom_1, threshold_symptom_2])
    reported_symptom_1 = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_symptom_2 = create(:bool_symptom, bool_value: true, threshold_operator: 'Equal', name: 'fever', label: 'Fever')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom_1, reported_symptom_2], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)
    # Assert symptomatic when group 1 symptom is true regardless of what a group 2 symptom has for a value
    assert assessment.symptomatic?
    reported_symptom_2.value = false
    assert assessment.symptomatic?
  end
end
