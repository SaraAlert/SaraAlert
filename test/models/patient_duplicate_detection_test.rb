# frozen_string_literal: true

require 'test_case'

class PatientDuplicateDetectionTest < ActiveSupport::TestCase
  def setup
    Patient.destroy_all
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: 'Male', user_defined_id_statelocal: 'asdf123')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', sex: 'Male')
    create(:patient, first_name: 'Deckard', last_name: 'Cain')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', sex: 'Male')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31')
    create(:patient, first_name: 'Deckard', last_name: 'Cain')
    create(:patient, first_name: 'Deckard', last_name: 'Cain')
    create(:patient, first_name: 'Deckard', last_name: 'Cain')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-30')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: 'Female')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-30', sex: 'Male')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', sex: 'Female')
    create(:patient, first_name: 'Deckar', last_name: 'Cain', date_of_birth: '1996-12-31', sex: 'Male')
    create(:patient, first_name: 'Deckard', last_name: 'Cai', date_of_birth: '1996-12-31', sex: 'Male')
  end

  test 'duplicate_data finds duplicate with input of FN LN Sex DoB ID' do
    patient_dup = { first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: 'Male', user_defined_id_statelocal: 'asdf123' }

    duplicate_data = Patient.duplicate_data_detection(patient_dup)

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 1,
                     fields: ['State/Local ID']
                   },
                   {
                     count: 1,
                     fields: ['First Name', 'Last Name', 'Sex', 'Date of Birth']
                   },
                   {
                     count: 2,
                     fields: ['First Name', 'Last Name', 'Sex']
                   },
                   {
                     count: 3,
                     fields: ['First Name', 'Last Name', 'Date of Birth']
                   },
                   {
                     count: 4,
                     fields: ['First Name', 'Last Name']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of FN LN DoB' do
    patient_dup = { first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31' }

    duplicate_data = Patient.duplicate_data_detection(patient_dup)

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 5,
                     fields: ['First Name', 'Last Name', 'Date of Birth']
                   },
                   {
                     count: 7,
                     fields: ['First Name', 'Last Name']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of FN LN Sex' do
    patient_dup = { first_name: 'Deckard', last_name: 'Cain', sex: 'Male' }

    duplicate_data = Patient.duplicate_data_detection(patient_dup)

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 4,
                     fields: ['First Name', 'Last Name', 'Sex']
                   },
                   {
                     count: 8,
                     fields: ['First Name', 'Last Name']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of FN LN' do
    patient_dup = { first_name: 'Deckard', last_name: 'Cain' }

    duplicate_data = Patient.duplicate_data_detection(patient_dup)

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 14,
                     fields: ['First Name', 'Last Name']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of FN ID' do
    patient_dup = { first_name: 'Deckard', user_defined_id_statelocal: 'asdf123' }

    duplicate_data = Patient.duplicate_data_detection(patient_dup)

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 1,
                     fields: ['State/Local ID']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of LN ID' do
    patient_dup = { last_name: 'Cain', user_defined_id_statelocal: 'asdf123' }

    duplicate_data = Patient.duplicate_data_detection(patient_dup)

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 1,
                     fields: ['State/Local ID']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of ID' do
    patient_dup = { user_defined_id_statelocal: 'asdf123' }

    duplicate_data = Patient.duplicate_data_detection(patient_dup)

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 1,
                     fields: ['State/Local ID']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of ID with extra spaces' do
    patient_dup = { user_defined_id_statelocal: ' asdf123 ' }

    duplicate_data = Patient.duplicate_data_detection(patient_dup)

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 1,
                     fields: ['State/Local ID']
                   }
                 ])
  end

  test 'duplicate_data does NOT find duplicate with input of FN LN Sex DoB ID' do
    patient_dup = { first_name: 'Cain', last_name: 'Deckard', date_of_birth: '1996-12-31', sex: 'Male', user_defined_id_statelocal: '123abc' }
    duplicate_data = Patient.duplicate_data_detection(patient_dup)

    assert_not duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [])
  end
end
