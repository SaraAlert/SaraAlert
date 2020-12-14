# frozen_string_literal: true

require 'test_case'
require_relative '../test_helpers/symptom_test_helper'

class AssessmentTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'update patient linelist' do
    patient = create(:patient)

    # Create assessment 1 as asymptomatic
    timestamp_1 = 5.days.ago
    assessment_1 = create(:assessment, patient: patient, symptomatic: false, created_at: timestamp_1)
    assert_nil patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Update assessment 1 to be symptomatic
    timestamp_1 = 10.days.ago
    assessment_1.update(symptomatic: true, created_at: timestamp_1)
    assert_equal timestamp_1.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Create assessment 2 as symptomatic
    timestamp_2 = 12.days.ago
    assessment_2 = create(:assessment, patient: patient, symptomatic: true, created_at: timestamp_2)
    reported_condition_2 = create(:reported_condition, assessment_id: assessment_2.id)
    symptom_2 = create(:symptom, condition_id: reported_condition_2.id, type: 'BoolSymptom', name: 'fever', bool_value: false)
    assert_equal timestamp_2.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Update assessment 2 to include fever
    symptom_2.update(bool_value: true)
    patient.reload.latest_fever_or_fever_reducer_at
    assert_in_delta timestamp_2, patient.latest_fever_or_fever_reducer_at, 1

    # Update assessment 2 to not include fever
    symptom_2.update(bool_value: false)
    patient.reload.latest_fever_or_fever_reducer_at
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Create assessment 3 as symptomatic
    timestamp_3 = 14.days.ago
    assessment_3 = create(:assessment, patient: patient, symptomatic: true, created_at: timestamp_3)
    assert_equal timestamp_3.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Update assessment 3 to be asymptomatic
    assessment_3.update(symptomatic: false)
    assert_equal timestamp_2.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Manually update symptom onset
    symptom_onset_timestamp = 16.days.ago
    patient.update(user_defined_symptom_onset: true, symptom_onset: symptom_onset_timestamp)

    # Update assessment 3 as symptomatic
    timestamp_3 = 18.days.ago
    assessment_3.update(symptomatic: true, created_at: timestamp_3)
    assert_equal symptom_onset_timestamp.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Update assessment 3 to be asymptomatic
    assessment_3.update(symptomatic: false)
    assert_equal symptom_onset_timestamp.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Turn off manual symptom onset override
    patient.update(user_defined_symptom_onset: false)

    # Update assessment 3 as symptomatic
    timestamp_3 = 18.days.ago
    assessment_3.update(symptomatic: true, created_at: timestamp_3)
    assert_equal timestamp_3.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Update assessment 3 to be asymptomatic
    assessment_3.update(symptomatic: false)
    assert_equal timestamp_2.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Destroy assessment 3
    assessment_3.destroy
    assert_equal timestamp_2.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Update assessment 2 date
    timestamp_2 = 1.day.ago
    assessment_2.update(created_at: timestamp_2)
    assert_equal timestamp_1.to_date, patient.symptom_onset
    assert_in_delta timestamp_2, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Update assessment 1 to be asymptomatic
    assessment_1.update!(symptomatic: false)
    assert_equal timestamp_2.to_date, patient.symptom_onset
    assert_in_delta timestamp_2, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Destroy assessment 2
    assessment_2.destroy!
    assert_nil patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Update assessment 1 to be symptomatic
    assessment_1.update!(symptomatic: true)
    assert_equal timestamp_1.to_date, patient.symptom_onset
    assert_in_delta timestamp_1, patient.latest_assessment_at, 1
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Create assessment 4 with fever
    timestamp_4 = 1.day.ago
    assessment_4 = create(:assessment, patient: patient, symptomatic: true, created_at: timestamp_4)
    reported_condition_4 = create(:reported_condition, assessment_id: assessment_4.id)
    symptom_4 = create(:symptom, condition_id: reported_condition_4.id, type: 'BoolSymptom', name: 'fever', bool_value: true)
    assert_equal timestamp_1.to_date, patient.symptom_onset
    assert_in_delta timestamp_4, patient.latest_assessment_at, 1
    patient.reload.latest_fever_or_fever_reducer_at
    assert_in_delta timestamp_4, patient.latest_fever_or_fever_reducer_at, 1

    # Destroy fever symptom
    symptom_4.destroy
    patient.reload.latest_fever_or_fever_reducer_at
    assert_nil patient.latest_fever_or_fever_reducer_at

    # Destroy assessments 1 and 4
    assessment_1.destroy
    assessment_4.destroy
    assert_nil patient.symptom_onset
    assert_nil patient.latest_assessment_at
    assert_nil patient.latest_fever_or_fever_reducer_at
    assert_empty patient.assessments
  end

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
    reported_symptom.update(value: 90.1)
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is not less than 90.1
    reported_symptom.update(value: 91)
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
    reported_symptom.update(value: 90.1)
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is not less than or equal 90.1
    reported_symptom.update(value: 91)
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
    reported_symptom.update(value: 90.1)
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not less than 90.1
    reported_symptom.update(value: 90)
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
    reported_symptom.update(value: 90.1)
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not greater than or equal 90.1
    reported_symptom.update(value: 90)
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
    reported_symptom.update(value: 91.1)
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
    reported_symptom.update(value: 91.1)
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
    reported_symptom.update(value: 91)
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 91 is not less than 91
    reported_symptom.update(value: 91)
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
    reported_symptom.update(value: 91)
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 92 is not less than or equal 91
    reported_symptom.update(value: 92)
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
    reported_symptom.update(value: 91)
    assert_not assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not less than 91
    reported_symptom.update(value: 90)
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
    reported_symptom.update(value: 91)
    assert assessment.symptom_passes_threshold('pulse-ox')
    # Assert 90 is not greater than or equal 91
    reported_symptom.update(value: 90)
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
    reported_symptom.update(value: 90)
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
    reported_symptom.update(value: 90)
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
    reported_symptom.update(value: false)
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
    reported_symptom.update(value: true)
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
    reported_symptom_2.update(value: false)
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

  test 'get reported symptom value' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)

    assert_equal(assessment.get_reported_symptom_value(reported_symptom.name), reported_symptom.value)

    reported_condition.destroy!
    assessment.reload
    assert_nil(assessment.get_reported_symptom_value(reported_symptom.value))
  end

  test 'all symptom names' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom_1 = create(:integer_symptom, int_value: 91, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    threshold_symptom_2 = create(:bool_symptom, bool_value: false, threshold_operator: 'Not Equal', name: 'fever', label: 'Fever')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom_1, threshold_symptom_2])
    reported_symptom_1 = create(:integer_symptom, int_value: 91, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_symptom_2 = create(:bool_symptom, bool_value: false, threshold_operator: 'Not Equal', name: 'fever', label: 'Fever')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom_1, reported_symptom_2], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)

    assert_equal(assessment.all_symptom_names, [threshold_symptom_1.name, threshold_symptom_2.name])

    threshold_symptom_1.update(name: nil)
    assert_equal(assessment.all_symptom_names, [threshold_symptom_1.name, threshold_symptom_2.name])

    threshold_symptom_1.update(name: 'pulse-ox')
    threshold_symptom_2.update(name: nil)
    assert_equal(assessment.all_symptom_names, [threshold_symptom_1.name, threshold_symptom_2.name])

    threshold_symptom_1.update(name: nil)
    threshold_symptom_2.update(name: nil)
    assert_equal(assessment.all_symptom_names, [threshold_symptom_1.name, threshold_symptom_2.name])
  end

  test 'get reported symptom by name' do
    threshold_condition_hash = Faker::Alphanumeric.alphanumeric(number: 64)
    threshold_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    create(:threshold_condition, threshold_condition_hash: threshold_condition_hash, symptoms: [threshold_symptom])
    reported_symptom = create(:integer_symptom, int_value: 91, threshold_operator: 'Greater Than Or Equal', name: 'pulse-ox', label: 'Pulse Ox')
    reported_condition = create(:reported_condition, symptoms: [reported_symptom], threshold_condition_hash: threshold_condition_hash)
    patient = create(:patient)
    assessment = create(:assessment, reported_condition: reported_condition, patient: patient)

    assert_equal(assessment.get_reported_symptom_by_name(reported_symptom.name), reported_symptom)

    assert_nil(assessment.get_reported_symptom_by_name('fake symptom name'))
  end
end
