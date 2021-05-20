# frozen_string_literal: true

require 'test_case'

class PatientQueryHelperTest < ActionView::TestCase
  # --- BOOLEAN ADVANCED FILTER QUERIES --- #

  test 'advanced filter blocked sms properly filters those with blocked numbers' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user, primary_telephone: '1111111111')
    patient_2 = create(:patient, creator: user, primary_telephone: '2222222222')
    patient_3 = create(:patient, creator: user, primary_telephone: '3333333333')
    BlockedNumber.destroy_all
    BlockedNumber.create(phone_number: '1111111111')
    BlockedNumber.create(phone_number: '2222222222')
    patients = Patient.all

    filters = [{ filterOption: {}, additionalFilterOption: nil, value: nil }]
    filters[0][:filterOption]['name'] = 'sms-blocked'
    tz_offset = 300

    # Check for monitorees who have blocked the system
    filters[0][:value] = true
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # Check for monitorees who have NOT blocked the system
    filters[0][:value] = false
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_3]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  # --- SEARCH ADVANCED FILTER QUERIES --- #

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

  # --- MULTI ADVANCED FILTER QUERIES --- #

  test 'advanced filter laboratory single filter option results' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, result: 'positive')
    create(:laboratory, patient: patient_1, result: 'negative')
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, result: 'negative')
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3, result: 'indeterminate')
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, result: 'positive')
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5, result: 'negative')
    create(:laboratory, patient: patient_5, result: 'indeterminate')
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, result: 'positive')
    create(:laboratory, patient: patient_6, result: 'positive')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'result', value: 'positive' }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4, patient_6]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory single filter option test type' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, lab_type: 'PCR')
    create(:laboratory, patient: patient_1, lab_type: 'Antigen')
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, lab_type: 'Antigen')
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3, lab_type: 'Total Antibody')
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, lab_type: 'PCR')
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5, lab_type: 'Total Antibody')
    create(:laboratory, patient: patient_5, lab_type: 'Other')
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, lab_type: 'PCR')
    create(:laboratory, patient: patient_6, lab_type: 'PCR')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'lab-type', value: 'PCR' }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4, patient_6]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory single filter option specimen collection date' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, specimen_collection: DateTime.new(2021, 3, 1))
    create(:laboratory, patient: patient_1, specimen_collection: DateTime.new(2021, 4, 1))
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, specimen_collection: DateTime.new(2021, 3, 24))
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3, specimen_collection: DateTime.new(2021, 3, 25))
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, specimen_collection: DateTime.new(2021, 3, 26))
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5, specimen_collection: DateTime.new(2021, 3, 1))
    create(:laboratory, patient: patient_5, specimen_collection: DateTime.new(2021, 3, 15))
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, specimen_collection: DateTime.new(2021, 4, 1))
    create(:laboratory, patient: patient_6, specimen_collection: DateTime.new(2021, 4, 3))
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'specimen-collection', value: { when: 'before', date: '2021-03-25' } }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_5]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory single filter option report date' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, report: DateTime.new(2021, 3, 1))
    create(:laboratory, patient: patient_1, report: DateTime.new(2021, 4, 1))
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, report: DateTime.new(2021, 3, 24))
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3, report: DateTime.new(2021, 3, 25))
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, report: DateTime.new(2021, 3, 26))
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5, report: DateTime.new(2021, 3, 1))
    create(:laboratory, patient: patient_5, report: DateTime.new(2021, 3, 15))
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, report: DateTime.new(2021, 4, 1))
    create(:laboratory, patient: patient_6, report: DateTime.new(2021, 4, 3))
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'report', value: { when: 'after', date: '2021-03-25' } }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4, patient_6]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory single filter option muliple values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, result: 'positive', lab_type: 'PCR')
    create(:laboratory, patient: patient_1, result: 'positive', lab_type: 'Antigen')
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, result: 'positive', lab_type: 'Antigen')
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3, result: 'positive', lab_type: 'Total Antibody')
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, result: 'negative', lab_type: 'PCR')
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'PCR')
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'PCR')
    create(:laboratory, patient: patient_5, result: 'negative', lab_type: 'PCR')
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'Antigen')
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, result: 'negative', lab_type: 'PCR')
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'Antigen')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'result', value: 'positive' }, { name: 'lab-type', value: 'PCR' }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_5]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory single filter option all values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_1, result: 'positive', lab_type: 'Antigen', specimen_collection: DateTime.new(2021, 3, 15),
                        report: DateTime.new(2021, 3, 18))
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, result: 'positive', lab_type: 'Antigen', specimen_collection: DateTime.new(2021, 3, 15),
                        report: DateTime.new(2021, 3, 28))
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 15),
                        report: DateTime.new(2021, 3, 18))
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 15),
                        report: DateTime.new(2021, 3, 28))
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 1),
                        report: DateTime.new(2021, 4, 1))
    create(:laboratory, patient: patient_5, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 1),
                        report: DateTime.new(2021, 3, 4))
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'Antigen', specimen_collection: DateTime.new(2021, 3, 15),
                        report: DateTime.new(2021, 3, 16))
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'Antigen', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 25),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 25))
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {},
                 value: [{ name: 'result', value: 'positive' }, { name: 'lab-type', value: 'PCR' },
                         { name: 'specimen-collection', value: { when: 'before', date: '2021-03-25' } },
                         { name: 'report', value: { when: 'after', date: '2021-03-25' } }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_5]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory multiple filter options some values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, result: 'positive', lab_type: 'PCR')
    create(:laboratory, patient: patient_1, result: 'positive', lab_type: 'Antigen')
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, result: 'positive', lab_type: 'Antigen')
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3, result: 'negative', lab_type: 'Antigen')
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, result: 'positive', lab_type: 'PCR')
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5, result: 'negative', lab_type: 'PCR')
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'PCR')
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'PCR')
    create(:laboratory, patient: patient_6, result: 'negative', lab_type: 'PCR')
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'Antigen')
    create(:laboratory, patient: patient_6, result: 'negative', lab_type: 'Antigen')
    patient_7 = create(:patient, creator: user)
    create(:laboratory, patient: patient_7, result: 'positive', lab_type: 'PCR')
    create(:laboratory, patient: patient_7, result: 'negative', lab_type: 'PCR')
    create(:laboratory, patient: patient_7, result: 'negative', lab_type: 'Antigen')
    patient_8 = create(:patient, creator: user)
    create(:laboratory, patient: patient_8, result: 'negative', lab_type: 'PCR')
    create(:laboratory, patient: patient_8, result: 'negative', lab_type: 'Antigen')
    create(:laboratory, patient: patient_8, result: 'positive', lab_type: 'Antigen')
    create(:patient, creator: user)

    patients = Patient.all
    filter_option_1 = { filterOption: {}, value: [{ name: 'result', value: 'positive' }, { name: 'lab-type', value: 'PCR' }] }
    filter_option_2 = { filterOption: {}, value: [{ name: 'result', value: 'positive' }, { name: 'lab-type', value: 'Antigen' }] }
    filter_option_1[:filterOption]['name'] = 'lab-result'
    filter_option_2[:filterOption]['name'] = 'lab-result'
    filters = [filter_option_1, filter_option_2]
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_6]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory multiple filter options all values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_1, result: 'negative', lab_type: 'Antigen', specimen_collection: DateTime.new(2021, 3, 15),
                        report: DateTime.new(2021, 3, 18))
    create(:laboratory, patient: patient_1, result: 'indeterminate', lab_type: 'Antigen', specimen_collection: DateTime.new(2021, 3, 5),
                        report: DateTime.new(2021, 3, 28))
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, result: 'positive', lab_type: 'Antigen', specimen_collection: DateTime.new(2021, 3, 15),
                        report: DateTime.new(2021, 3, 18))
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 1),
                        report: DateTime.new(2021, 3, 3))
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 15),
                        report: DateTime.new(2021, 3, 18))
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 1),
                        report: DateTime.new(2021, 4, 1))
    create(:laboratory, patient: patient_5, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 1),
                        report: DateTime.new(2021, 3, 4))
    create(:laboratory, patient: patient_5, result: 'indeterminate', lab_type: 'Antigen', specimen_collection: DateTime.new(2021, 3, 15),
                        report: DateTime.new(2021, 3, 16))
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 25),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_5, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 25))
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_6, result: 'indeterminate', lab_type: 'Antigen', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 25),
                        report: DateTime.new(2021, 3, 26))
    create(:laboratory, patient: patient_6, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.new(2021, 3, 24),
                        report: DateTime.new(2021, 3, 25))
    create(:patient, creator: user)

    patients = Patient.all
    filter_option_1 = { filterOption: {},
                        value: [{ name: 'result', value: 'positive' }, { name: 'lab-type', value: 'PCR' },
                                { name: 'specimen-collection', value: { when: 'before', date: '2021-03-25' } },
                                { name: 'report', value: { when: 'after', date: '2021-03-25' } }] }
    filter_option_2 = { filterOption: {},
                        value: [{ name: 'result', value: 'indeterminate' }, { name: 'lab-type', value: 'Antigen' },
                                { name: 'specimen-collection', value: { when: 'before', date: '2021-03-25' } },
                                { name: 'report', value: { when: 'after', date: '2021-03-25' } }] }
    filter_option_1[:filterOption]['name'] = 'lab-result'
    filter_option_2[:filterOption]['name'] = 'lab-result'
    filters = [filter_option_1, filter_option_2]
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_6]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option vaccine group' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, group_name: 'COVID-19')
    create(:vaccine, patient: patient_1, group_name: 'COVID-19')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, group_name: 'COVID-19')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'vaccine-group', value: 'COVID-19' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option product name' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, product_name: 'Moderna COVID-19 Vaccine')
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, product_name: 'Janssen (J&J) COVID-19 Vaccine')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, product_name: 'Moderna COVID-19 Vaccine')
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, product_name: 'Unknown')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine')
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine')
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, product_name: 'Moderna COVID-19 Vaccine')
    create(:vaccine, patient: patient_6, product_name: 'Moderna COVID-19 Vaccine')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'product-name', value: 'Moderna COVID-19 Vaccine' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_3, patient_6]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option administration date before' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, administration_date: DateTime.new(2021, 3, 1))
    create(:vaccine, patient: patient_1, administration_date: DateTime.new(2021, 4, 1))
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, administration_date: DateTime.new(2021, 3, 24))
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, administration_date: DateTime.new(2021, 3, 25))
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, administration_date: DateTime.new(2021, 3, 26))
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, administration_date: DateTime.new(2021, 3, 1))
    create(:vaccine, patient: patient_5, administration_date: DateTime.new(2021, 3, 15))
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, administration_date: DateTime.new(2021, 4, 1))
    create(:vaccine, patient: patient_6, administration_date: DateTime.new(2021, 4, 3))
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'administration-date', value: { when: 'before', date: '2021-03-25' } }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_5]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option administration date after' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, administration_date: DateTime.new(2021, 3, 1))
    create(:vaccine, patient: patient_1, administration_date: DateTime.new(2021, 4, 1))
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, administration_date: DateTime.new(2021, 3, 24))
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, administration_date: DateTime.new(2021, 3, 25))
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, administration_date: DateTime.new(2021, 3, 26))
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, administration_date: DateTime.new(2021, 3, 1))
    create(:vaccine, patient: patient_5, administration_date: DateTime.new(2021, 3, 15))
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, administration_date: DateTime.new(2021, 4, 1))
    create(:vaccine, patient: patient_6, administration_date: DateTime.new(2021, 4, 3))
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'administration-date', value: { when: 'after', date: '2021-03-25' } }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4, patient_6]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option dose number blank' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, dose_number: '1')
    create(:vaccine, patient: patient_1, dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, dose_number: 'Unknown')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, dose_number: nil)
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, dose_number: '')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, dose_number: '')
    create(:vaccine, patient: patient_5, dose_number: nil)
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, dose_number: '1')
    create(:vaccine, patient: patient_6, dose_number: '')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'dose-number', value: '' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_3, patient_4, patient_5, patient_6]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option dose number not blank' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, dose_number: '1')
    create(:vaccine, patient: patient_1, dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, dose_number: '1')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, dose_number: '')
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, dose_number: 'Unknown')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, dose_number: '1')
    create(:vaccine, patient: patient_5, dose_number: nil)
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, dose_number: '1')
    create(:vaccine, patient: patient_6, dose_number: '1')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'dose-number', value: '1' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_5, patient_6]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option muliple values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: 'Unknown')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: nil)
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, product_name: 'Janssen (J&J) COVID-19 Vaccine', dose_number: '1')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_5, product_name: 'Janssen (J&J) COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_5, product_name: 'Unknown', dose_number: 'Unknown')
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '2')
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, product_name: 'Moderna COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_6, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '2')
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '1')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine' }, { name: 'dose-number', value: '1' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_5, patient_7]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option all values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_1, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 4, 11), dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: 'Unknown')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 25), dose_number: '1')
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, group_name: 'COVID-19', product_name: 'Janssen (J&J) COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Janssen (J&J) COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 24),
                     dose_number: 'Unknown')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 4, 13), dose_number: '2')
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Moderna COVID-19 Vaccine', administration_date: DateTime.new(2021, 3, 24),
                     dose_number: '1')
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 4, 11), dose_number: '2')
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {},
                 value: [{ name: 'vaccine-group', value: 'COVID-19' }, { name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine' },
                         { name: 'administration-date', value: { when: 'before', date: '2021-03-25' } },
                         { name: 'dose-number', value: '1' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_5, patient_7]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination multiple filter options some values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: 'Unknown')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: nil)
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, product_name: 'Janssen (J&J) COVID-19 Vaccine', dose_number: '1')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_5, product_name: 'Janssen (J&J) COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_5, product_name: 'Unknown', dose_number: 'Unknown')
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '2')
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, product_name: 'Moderna COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_6, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '2')
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, product_name: 'Pfizer-BioNTech COVID-19 Vaccine', dose_number: '1')
    create(:patient, creator: user)

    patients = Patient.all
    filter_option_1 = { filterOption: {}, value: [{ name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine' }, { name: 'dose-number', value: '1' }] }
    filter_option_2 = { filterOption: {}, value: [{ name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine' }, { name: 'dose-number', value: '2' }] }
    filter_option_1[:filterOption]['name'] = 'vaccination'
    filter_option_2[:filterOption]['name'] = 'vaccination'
    filters = [filter_option_1, filter_option_2]
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_5]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination multiple filter options all values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_1, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 4, 11), dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26),
                     dose_number: 'Unknown')
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_4, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: nil)
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 25), dose_number: '1')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 4, 18), dose_number: '2')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: 'Unknown')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: nil)
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Moderna COVID-19 Vaccine', administration_date: DateTime.new(2021, 3, 25),
                     dose_number: '1')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: nil)
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 26), dose_number: nil)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 25), dose_number: nil)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 5), dose_number: nil)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: '2')
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 25), dose_number: '1')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 4, 18), dose_number: '2')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: 'Unknown')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: nil)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Moderna COVID-19 Vaccine', administration_date: DateTime.new(2021, 3, 25),
                     dose_number: '1')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 26), dose_number: nil)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 25), dose_number: nil)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 5), dose_number: nil)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: '2')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: '')
    create(:patient, creator: user)

    patients = Patient.all
    filter_option_1 = { filterOption: {},
                        value: [{ name: 'vaccine-group', value: 'COVID-19' }, { name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine' },
                                { name: 'administration-date', value: { when: 'before', date: '2021-03-25' } },
                                { name: 'dose-number', value: '1' }] }
    filter_option_2 = { filterOption: {},
                        value: [{ name: 'vaccine-group', value: 'COVID-19' }, { name: 'product-name', value: 'Unknown' },
                                { name: 'administration-date', value: { when: 'after', date: '2021-03-25' } },
                                { name: 'dose-number', value: '' }] }
    filter_option_1[:filterOption]['name'] = 'vaccination'
    filter_option_2[:filterOption]['name'] = 'vaccination'
    filters = [filter_option_1, filter_option_2]
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_4, patient_7]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end
end
