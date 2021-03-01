# frozen_string_literal: true

require 'test_case'

class PatientQueryHelperTest < ActionView::TestCase
  test 'advanced filter close contact with known case id exact match single value' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user, contact_of_known_case_id: '111')
    create(:patient, creator: user, contact_of_known_case_id: '  111')
    create(:patient, creator: user, contact_of_known_case_id: '111    ')
    create(:patient, creator: user, contact_of_known_case_id: '1112')
    create(:patient, creator: user, contact_of_known_case_id: '2222, 11111, 333')
    patient_2 = create(:patient, creator: user, contact_of_known_case_id: '111,222')
    patient_3 = create(:patient, creator: user, contact_of_known_case_id: '222,111')
    patient_4 = create(:patient, creator: user, contact_of_known_case_id: '222, 111')
    patient_5 = create(:patient, creator: user, contact_of_known_case_id: '222,    111')
    patient_6 = create(:patient, creator: user, contact_of_known_case_id: '222, 111, 333')
    patient_7 = create(:patient, creator: user, contact_of_known_case_id: '222, 111 , 333')
    patient_8 = create(:patient, creator: user, contact_of_known_case_id: '222,   111  , 333')
    create(:patient, creator: user, contact_of_known_case_id: '222, 11')

    patients = Patient.all
    filters = [{ filterOption: {}, additionalFilterOption: 'Exact Match', value: '111' }]
    filters[0][:filterOption]['name'] = 'close-contact-with-known-case-id'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3, patient_4, patient_5, patient_6, patient_7, patient_8]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter close contact with known case id exact match multiple value' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user, contact_of_known_case_id: '111')
    create(:patient, creator: user, contact_of_known_case_id: '1112')
    create(:patient, creator: user, contact_of_known_case_id: '567')
    create(:patient, creator: user, contact_of_known_case_id: '123456789')
    create(:patient, creator: user, contact_of_known_case_id: '2222, 56789, 333')
    patient_2 = create(:patient, creator: user, contact_of_known_case_id: '111,222')
    patient_3 = create(:patient, creator: user, contact_of_known_case_id: '222,5678')
    patient_4 = create(:patient, creator: user, contact_of_known_case_id: '222, 111')
    patient_5 = create(:patient, creator: user, contact_of_known_case_id: '222,  111')
    patient_6 = create(:patient, creator: user, contact_of_known_case_id: '1234, 5678, 4321')
    patient_7 = create(:patient, creator: user, contact_of_known_case_id: '111, 222, 333')
    patient_8 = create(:patient, creator: user, contact_of_known_case_id: '123, 4, 5678')

    patients = Patient.all
    filters = [{ filterOption: {}, additionalFilterOption: 'Exact Match', value: '111, 5678' }]
    filters[0][:filterOption]['name'] = 'close-contact-with-known-case-id'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3, patient_4, patient_5, patient_6, patient_7, patient_8]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter close contact with known case id contains single value' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user, contact_of_known_case_id: '111')
    patient_2 = create(:patient, creator: user, contact_of_known_case_id: '  111')
    patient_3 = create(:patient, creator: user, contact_of_known_case_id: '111    ')
    patient_4 = create(:patient, creator: user, contact_of_known_case_id: '1112')
    patient_5 = create(:patient, creator: user, contact_of_known_case_id: '2222, 11111, 333')
    patient_6 = create(:patient, creator: user, contact_of_known_case_id: '111,222')
    patient_7 = create(:patient, creator: user, contact_of_known_case_id: '222,111')
    patient_8 = create(:patient, creator: user, contact_of_known_case_id: '222, 111')
    patient_9 = create(:patient, creator: user, contact_of_known_case_id: '222,    111')
    patient_10 = create(:patient, creator: user, contact_of_known_case_id: '222, 111, 333')
    patient_11 = create(:patient, creator: user, contact_of_known_case_id: '222, 111 , 333')
    patient_12 = create(:patient, creator: user, contact_of_known_case_id: '222,   111  , 333')
    create(:patient, creator: user, contact_of_known_case_id: '222, 11')

    patients = Patient.all
    filters = [{ filterOption: {}, additionalFilterOption: 'Contains', value: '111' }]
    filters[0][:filterOption]['name'] = 'close-contact-with-known-case-id'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3, patient_4, patient_5, patient_6, patient_7, patient_8, patient_9, patient_10, patient_11,
                               patient_12]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter close contact with known case id contains multiple value' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user, contact_of_known_case_id: '111')
    patient_2 = create(:patient, creator: user, contact_of_known_case_id: '1112')
    create(:patient, creator: user, contact_of_known_case_id: '567')
    patient_3 = create(:patient, creator: user, contact_of_known_case_id: '123456789')
    patient_4 = create(:patient, creator: user, contact_of_known_case_id: '2222, 56789, 333')
    patient_5 = create(:patient, creator: user, contact_of_known_case_id: '111,222')
    patient_6 = create(:patient, creator: user, contact_of_known_case_id: '222,5678')
    patient_7 = create(:patient, creator: user, contact_of_known_case_id: '222, 111')
    patient_8 = create(:patient, creator: user, contact_of_known_case_id: '222,  111')
    patient_9 = create(:patient, creator: user, contact_of_known_case_id: '1234, 5678, 4321')
    patient_10 = create(:patient, creator: user, contact_of_known_case_id: '111, 222, 333')
    patient_11 = create(:patient, creator: user, contact_of_known_case_id: '123, 4, 5678')

    patients = Patient.all
    filters = [{ filterOption: {}, additionalFilterOption: 'Contains', value: '111, 5678' }]
    filters[0][:filterOption]['name'] = 'close-contact-with-known-case-id'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3, patient_4, patient_5, patient_6, patient_7, patient_8, patient_9, patient_10, patient_11]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end
end
