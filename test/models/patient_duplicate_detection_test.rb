# frozen_string_literal: true

require 'test_case'

class PatientDuplicateDetectionTest < ActiveSupport::TestCase
  def setup
    Patient.destroy_all
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: 'Male', user_defined_id_statelocal: 'asdf123')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: nil)
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: nil, sex: 'Male')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: nil, sex: nil)
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: nil, sex: 'Male')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: nil)
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: nil)
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: nil, sex: nil)
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: nil, sex: nil)
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: nil, sex: nil)
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-30', sex: nil)
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: 'Female')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-30', sex: 'Male')
    create(:patient, first_name: 'Deckard', last_name: 'Cain', date_of_birth: nil, sex: 'Female')
    create(:patient, first_name: 'Deckar', last_name: 'Cain', date_of_birth: '1996-12-31', sex: 'Male')
    create(:patient, first_name: 'Deckard', last_name: 'Cai', date_of_birth: '1996-12-31', sex: 'Male')
  end

  test 'duplicate_data finds duplicate with input of FN LN Sex DoB ID' do
    patient_dup = Patient.new(first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: 'Male', user_defined_id_statelocal: 'asdf123')

    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth]&.strftime('%F'),
                                            patient_dup[:user_defined_id_statelocal])

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
    patient_dup = Patient.new(first_name: 'Deckard', last_name: 'Cain', date_of_birth: '1996-12-31', sex: nil, user_defined_id_statelocal: nil)

    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth]&.strftime('%F'),
                                            patient_dup[:user_defined_id_statelocal])

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
    patient_dup = Patient.new(first_name: 'Deckard', last_name: 'Cain', date_of_birth: nil, sex: 'Male', user_defined_id_statelocal: nil)

    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth]&.strftime('%F'),
                                            patient_dup[:user_defined_id_statelocal])

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
    patient_dup = Patient.new(first_name: 'Deckard', last_name: 'Cain', date_of_birth: nil, sex: nil, user_defined_id_statelocal: nil)

    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth]&.strftime('%F'),
                                            patient_dup[:user_defined_id_statelocal])

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 14,
                     fields: ['First Name', 'Last Name']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of FN ID' do
    patient_dup = Patient.new(first_name: 'Deckard', last_name: nil, date_of_birth: nil, sex: nil, user_defined_id_statelocal: 'asdf123')

    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth]&.strftime('%F'),
                                            patient_dup[:user_defined_id_statelocal])

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 1,
                     fields: ['State/Local ID']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of LN ID' do
    patient_dup = Patient.new(first_name: nil, last_name: 'Cain', date_of_birth: nil, sex: nil, user_defined_id_statelocal: 'asdf123')

    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth]&.strftime('%F'),
                                            patient_dup[:user_defined_id_statelocal])

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 1,
                     fields: ['State/Local ID']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate with input of ID' do
    patient_dup = Patient.new(first_name: nil, last_name: nil, date_of_birth: nil, sex: nil, user_defined_id_statelocal: 'asdf123')

    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth]&.strftime('%F'),
                                            patient_dup[:user_defined_id_statelocal])

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 1,
                     fields: ['State/Local ID']
                   }
                 ])
  end

  test 'duplicate_data does NOT find duplicate with input of FN LN Sex DoB ID' do
    patient_dup = Patient.new(first_name: 'Cain', last_name: 'Deckard', date_of_birth: '1996-12-31', sex: 'Male', user_defined_id_statelocal: '123abc')
    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth]&.strftime('%F'),
                                            patient_dup[:user_defined_id_statelocal])

    assert_not duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [])
  end
end
