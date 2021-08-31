# frozen_string_literal: true

require 'test_case'

# rubocop:disable Metrics/ClassLength
class PatientQueryHelperTest < ActionView::TestCase
  # --- BOOLEAN ADVANCED FILTER QUERIES --- #

  test 'advanced filter blocked sms' do
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have NOT blocked the system
    filters[0][:value] = false
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_3]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter ineligible for any recovery definition' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)

    # records eligible for recovery definition
    patient_1 = create(:patient, creator: user, isolation: true, symptom_onset: '2020-02-02')
    patient_2 = create(:patient, creator: user, isolation: true)
    create(:laboratory, patient: patient_2, result: 'positive', specimen_collection: '2020-02-02')
    patient_3 = create(:patient, creator: user, isolation: true)
    create(:laboratory, patient: patient_3, result: 'positive', specimen_collection: '2020-02-02')

    # records ineligible for recovery definition
    patient_4 = create(:patient, creator: user, isolation: true)
    patient_5 = create(:patient, creator: user, isolation: true)
    patient_6 = create(:patient, creator: user, isolation: true)
    create(:laboratory, patient: patient_6, result: 'positive')
    patient_7 = create(:patient, creator: user, isolation: true)
    create(:laboratory, patient: patient_7, specimen_collection: '2020-02-02')
    patient_8 = create(:patient, creator: user, isolation: true)
    create(:laboratory, patient: patient_8, result: 'negative', specimen_collection: '2020-02-02')

    # records in exposure should not be returned whether filter value is true or false
    create(:patient, creator: user, isolation: false)
    create(:patient, creator: user, isolation: false, symptom_onset: '2020-02-02')
    patient_9 = create(:patient, creator: user, isolation: false)
    create(:laboratory, patient: patient_9, result: 'positive', specimen_collection: '2020-02-02')

    patients = Patient.all
    filters = [{ filterOption: {}, additionalFilterOption: nil, value: nil }]
    filters[0][:filterOption]['name'] = 'ineligible-for-recovery-definition'
    tz_offset = 300

    # Check for monitorees who are ineligible for any recovery definition
    filters[0][:value] = true
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_4, patient_5, patient_6, patient_7, patient_8]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who are NOT ineligible for any recovery definition
    filters[0][:value] = false
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter unenrolled close contact' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:close_contact, patient: patient_1)
    create(:close_contact, patient: patient_1, enrolled_id: 111)
    patient_2 = create(:patient, creator: user)
    create(:close_contact, patient: patient_2)
    create(:close_contact, patient: patient_2)
    patient_3 = create(:patient, creator: user)
    create(:close_contact, patient: patient_3, enrolled_id: 333)
    create(:close_contact, patient: patient_3, enrolled_id: 334)
    create(:close_contact, patient: patient_3, enrolled_id: 335)
    patient_4 = create(:patient, creator: user)

    patients = Patient.all

    filters = [{ filterOption: {}, additionalFilterOption: nil, value: nil }]
    filters[0][:filterOption]['name'] = 'unenrolled-close-contact'
    tz_offset = 300

    # Check for monitorees who have at least one unenrolled close contact
    filters[0][:value] = true
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have no close contacts or only enrolled close contacts
    filters[0][:value] = false
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_3, patient_4]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  # --- COMBINATION ADVANCED FILTER QUERIES --- #

  test 'advanced filter laboratory single filter option results' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, result: 'positive')
    create(:laboratory, patient: patient_1, result: '')
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, result: 'negative')
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3)
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, result: 'positive')
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5)
    create(:laboratory, patient: patient_5, result: 'indeterminate')
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, result: 'positive')
    create(:laboratory, patient: patient_6, result: 'positive')
    patient_7 = create(:patient, creator: user)
    create(:laboratory, patient: patient_7, result: '')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'result', value: '' }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300

    # Check for monitorees who have a blank result
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_7, patient_3, patient_5]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a non-blank result
    filters[0][:value][0][:value] = 'positive'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4, patient_6]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory single filter option test type' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, lab_type: 'PCR')
    create(:laboratory, patient: patient_1, lab_type: '')
    patient_2 = create(:patient, creator: user)
    create(:laboratory, patient: patient_2, lab_type: 'Antigen')
    patient_3 = create(:patient, creator: user)
    create(:laboratory, patient: patient_3)
    patient_4 = create(:patient, creator: user)
    create(:laboratory, patient: patient_4, lab_type: 'PCR')
    patient_5 = create(:patient, creator: user)
    create(:laboratory, patient: patient_5)
    create(:laboratory, patient: patient_5, lab_type: 'Other')
    patient_6 = create(:patient, creator: user)
    create(:laboratory, patient: patient_6, lab_type: 'PCR')
    create(:laboratory, patient: patient_6, lab_type: 'PCR')
    patient_7 = create(:patient, creator: user)
    create(:laboratory, patient: patient_7, result: '')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'lab-type', value: '' }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300

    # Check for monitorees who have a blank lab type
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_3, patient_5, patient_7]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a non-blank lab type
    filters[0][:value][0][:value] = 'PCR'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4, patient_6]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory single filter option specimen collection date' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, specimen_collection: DateTime.new(2021, 3, 1))
    create(:laboratory, patient: patient_1, specimen_collection: DateTime.new(2021, 4, 1))
    create(:laboratory, patient: patient_1, specimen_collection: nil)
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
    patient_7 = create(:patient, creator: user)
    create(:laboratory, patient: patient_7, specimen_collection: nil)
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'specimen-collection', value: { when: '' } }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300

    # Check for monitorees who have a blank specimen collection date
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_7]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a specimen collection date "before"
    filters[0][:value][0][:value] = { when: 'before', date: '2021-03-25' }
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_5]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a specimen collection date "after"
    filters[0][:value][0][:value] = { when: 'after', date: '2021-03-25' }
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4, patient_6]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter laboratory single filter option report date' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:laboratory, patient: patient_1, report: DateTime.new(2021, 3, 1))
    create(:laboratory, patient: patient_1, report: DateTime.new(2021, 4, 1))
    create(:laboratory, patient: patient_1, report: nil)
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
    patient_7 = create(:patient, creator: user)
    create(:laboratory, patient: patient_7, report: nil)
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'report', value: { when: '' } }] }]
    filters[0][:filterOption]['name'] = 'lab-result'
    tz_offset = 300

    # Check for monitorees who have a blank report date
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_7]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a specimen collection date "before"
    filters[0][:value][0][:value] = { when: 'before', date: '2021-03-25' }
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_5]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a specimen collection date "after"
    filters[0][:value][0][:value] = { when: 'after', date: '2021-03-25' }
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4, patient_6]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option product name' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)')
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, product_name: 'Janssen (J&J) COVID-19 Vaccine')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)')
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, product_name: 'Unknown')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)')
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)')
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)')
    create(:vaccine, patient: patient_6, product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'product-name', value: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_3, patient_6]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option administration date' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, administration_date: DateTime.new(2021, 3, 1))
    create(:vaccine, patient: patient_1, administration_date: DateTime.new(2021, 4, 1))
    create(:vaccine, patient: patient_1, administration_date: nil)
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
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, administration_date: nil)
    patient_8 = create(:patient, creator: user)
    create(:vaccine, patient: patient_8, administration_date: DateTime.new(2021, 3, 1))
    create(:vaccine, patient: patient_8, administration_date: nil)
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'administration-date', value: { when: '' } }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300

    # Check for monitorees who have a blank report date
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_7, patient_8]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a report date "before"
    filters[0][:value][0][:value] = { when: 'before', date: '2021-03-25' }
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_5, patient_8]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a report date "after"
    filters[0][:value][0][:value] = { when: 'after', date: '2021-03-25' }
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4, patient_6]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option dose number' do
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
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, dose_number: '2')
    create(:vaccine, patient: patient_7, dose_number: '2')

    patients = Patient.all
    filters = [{ filterOption: {}, value: [{ name: 'dose-number', value: '' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300

    # Check for monitorees who have a blank dose number
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_3, patient_4, patient_5, patient_6]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a non-blank dose number
    filters[0][:value][0][:value] = '1'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_6]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option muliple values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '1')
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: 'Unknown')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: nil)
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, product_name: 'Janssen (J&J) COVID-19 Vaccine', dose_number: '1')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '1')
    create(:vaccine, patient: patient_5, product_name: 'Janssen (J&J) COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_5, product_name: 'Unknown', dose_number: 'Unknown')
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '2')
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)', dose_number: '1')
    create(:vaccine, patient: patient_6, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '2')
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '1')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {},
                 value: [{ name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)' }, { name: 'dose-number', value: '1' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_5, patient_7]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination single filter option all values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_1, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 4, 11), dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: 'Unknown')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 25), dose_number: '1')
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, group_name: 'COVID-19', product_name: 'Janssen (J&J) COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Janssen (J&J) COVID-19 Vaccine',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 24),
                     dose_number: 'Unknown')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 4, 13), dose_number: '2')
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 4, 11), dose_number: '2')
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:patient, creator: user)

    patients = Patient.all
    filters = [{ filterOption: {},
                 value: [{ name: 'vaccine-group', value: 'COVID-19' },
                         { name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)' },
                         { name: 'administration-date', value: { when: 'before', date: '2021-03-25' } },
                         { name: 'dose-number', value: '1' }] }]
    filters[0][:filterOption]['name'] = 'vaccination'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_5, patient_7]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination multiple filter options some values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '1')
    create(:vaccine, patient: patient_1, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: 'Unknown')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: nil)
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, product_name: 'Janssen (J&J) COVID-19 Vaccine', dose_number: '1')
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '1')
    create(:vaccine, patient: patient_5, product_name: 'Janssen (J&J) COVID-19 Vaccine', dose_number: '1')
    create(:vaccine, patient: patient_5, product_name: 'Unknown', dose_number: 'Unknown')
    create(:vaccine, patient: patient_5, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '2')
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)', dose_number: '1')
    create(:vaccine, patient: patient_6, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '2')
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', dose_number: '1')
    create(:patient, creator: user)

    patients = Patient.all
    filter_option_1 = { filterOption: {},
                        value: [{ name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)' },
                                { name: 'dose-number', value: '1' }] }
    filter_option_2 = { filterOption: {},
                        value: [{ name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)' },
                                { name: 'dose-number', value: '2' }] }
    filter_option_1[:filterOption]['name'] = 'vaccination'
    filter_option_2[:filterOption]['name'] = 'vaccination'
    filters = [filter_option_1, filter_option_2]
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_5]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  test 'advanced filter vaccination multiple filter options all values' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    create(:vaccine, patient: patient_1, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_1, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 4, 11), dose_number: '2')
    patient_2 = create(:patient, creator: user)
    create(:vaccine, patient: patient_2, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    patient_3 = create(:patient, creator: user)
    create(:vaccine, patient: patient_3, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26),
                     dose_number: 'Unknown')
    patient_4 = create(:patient, creator: user)
    create(:vaccine, patient: patient_4, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_4, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: nil)
    patient_5 = create(:patient, creator: user)
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 25), dose_number: '1')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 4, 18), dose_number: '2')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: 'Unknown')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: nil)
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)',
                     administration_date: DateTime.new(2021, 3, 25),
                     dose_number: '1')
    create(:vaccine, patient: patient_5, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: nil)
    patient_6 = create(:patient, creator: user)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 26), dose_number: nil)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 25), dose_number: nil)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 5), dose_number: nil)
    create(:vaccine, patient: patient_6, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: '2')
    patient_7 = create(:patient, creator: user)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: '1')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 25), dose_number: '1')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 4, 18), dose_number: '2')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: 'Unknown')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 24), dose_number: nil)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)',
                     administration_date: DateTime.new(2021, 3, 25),
                     dose_number: '1')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)',
                     administration_date: DateTime.new(2021, 3, 26), dose_number: nil)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 25), dose_number: nil)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 5), dose_number: nil)
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: '2')
    create(:vaccine, patient: patient_7, group_name: 'COVID-19', product_name: 'Unknown', administration_date: DateTime.new(2021, 3, 26), dose_number: '')
    create(:patient, creator: user)

    patients = Patient.all
    filter_option_1 = { filterOption: {},
                        value: [{ name: 'vaccine-group', value: 'COVID-19' },
                                { name: 'product-name', value: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)' },
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
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  # --- MULTI-SELECT ADVANCED FILTER QUERIES --- #

  test 'advanced filter assigned user filters by assigned user' do
    Patient.destroy_all
    user_1 = create(:public_health_enroller_user)
    user_2 = create(:public_health_enroller_user)
    user_3 = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user_1)
    patient_1.update_attribute('assigned_user', user_1[:id])
    patient_2 = create(:patient, creator: user_1)
    patient_2.update_attribute('assigned_user', user_1[:id])
    patient_3 = create(:patient, creator: user_2)
    patient_3.update_attribute('assigned_user', user_2[:id])
    patient_4 = create(:patient, creator: user_3)
    patient_4.update_attribute('assigned_user', user_3[:id])

    patients = Patient.all

    tz_offset = 240

    # Check for monitorees with assigned user user_1
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: user_1[:id], value: user_1[:id] }] }]
    filters[0][:filterOption]['name'] = 'assigned-user'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # Check for monitorees with assigned user user_1 or user_2 or user_3
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: user_1[:id], value: user_1[:id] },
                         { label: user_2[:id], value: user_2[:id] },
                         { label: user_3[:id], value: user_3[:id] }] }]
    filters[0][:filterOption]['name'] = 'assigned-user'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3, patient_4]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # Check for monitorees with assigned user user_1 or user_2
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: user_1[:id], value: user_1[:id] },
                         { label: user_2[:id], value: user_2[:id] }] }]
    filters[0][:filterOption]['name'] = 'assigned-user'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # No selected assigned user should not filter out any monitorees
    filters = [{ filterOption: {}, additionalFilterOption: nil, value: [] }]
    filters[0][:filterOption]['name'] = 'assigned-user'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3, patient_4]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # Invalid assigned user should not return any monitorees
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: -1, value: -1 }] }]
    filters[0][:filterOption]['name'] = 'assigned-user'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = []
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # Check for monitorees with assigned user user_1 or invalid assigned user
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: user_1[:id], value: user_1[:id] },
                         { label: -1, value: -1 }] }]
    filters[0][:filterOption]['name'] = 'assigned-user'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter jurisdiction filters by jurisdiction' do
    Patient.destroy_all
    user_1 = create(:public_health_enroller_user)
    user_2 = create(:public_health_enroller_user)
    user_3 = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user_1)
    patient_1.update!(jurisdiction_id: user_1[:jurisdiction_id])
    patient_2 = create(:patient, creator: user_1)
    patient_2.update!(jurisdiction_id: user_1[:jurisdiction_id])
    patient_3 = create(:patient, creator: user_2)
    patient_3.update!(jurisdiction_id: user_2[:jurisdiction_id])
    patient_4 = create(:patient, creator: user_3)
    patient_4.update!(jurisdiction_id: user_3[:jurisdiction_id])

    patients = Patient.all

    tz_offset = 240

    # Check for monitorees with jurisdiction of user_1
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: user_1[:jurisdiction_path], value: user_1[:jurisdiction_id] }] }]
    filters[0][:filterOption]['name'] = 'jurisdiction'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # Check for monitorees with jurisdiction of user_1 or user_2 or user_3
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: user_1[:jurisdiction_path], value: user_1[:jurisdiction_id] },
                         { label: user_2[:jurisdiction_path], value: user_2[:jurisdiction_id] },
                         { label: user_3[:jurisdiction_path], value: user_3[:jurisdiction_id] }] }]
    filters[0][:filterOption]['name'] = 'jurisdiction'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3, patient_4]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # Check for monitorees with jurisdiction of user_1 or user_2
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: user_1[:jurisdiction_path], value: user_1[:jurisdiction_id] },
                         { label: user_2[:jurisdiction_path], value: user_2[:jurisdiction_id] }] }]
    filters[0][:filterOption]['name'] = 'jurisdiction'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # No selected jurisdiction should not filter out any monitorees
    filters = [{ filterOption: {}, additionalFilterOption: nil, value: [] }]
    filters[0][:filterOption]['name'] = 'jurisdiction'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3, patient_4]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # Invalid jurisdiction should not return any monitorees
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: 'Not real jurisdiction', value: -1 }] }]
    filters[0][:filterOption]['name'] = 'jurisdiction'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = []
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)

    # Check for monitorees with jurisdiction of user_2 or invalid jurisdiction
    filters = [{ filterOption: {}, additionalFilterOption: nil,
                 value: [{ label: user_2[:jurisdiction_path], value: user_2[:jurisdiction_id] },
                         { label: 'Not real jurisdiction', value: -1 }] }]
    filters[0][:filterOption]['name'] = 'jurisdiction'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_3]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  # --- SELECT ADVANCED FILTER QUERIES --- #

  test 'advanced filter flagged for follow up filters those marked as flagged for follow up' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    patient_1.update!(follow_up_reason: 'Lost to Follow-up', follow_up_note: 'This is a test')
    patient_2 = create(:patient, creator: user)
    patient_2.update!(follow_up_reason: 'Duplicate', follow_up_note: 'This is a test')
    patient_3 = create(:patient, creator: user)
    patient_3.update!(follow_up_reason: 'Needs Interpretation')
    patient_4 = create(:patient, creator: user)
    patient_4.update!(follow_up_reason: 'Lost to Follow-up', follow_up_note: 'This is a test note')
    create(:patient, creator: user)

    patients = Patient.all
    # Check for monitorees who have any follow-up flag reason
    filters = [{ filterOption: {}, additionalFilterOption: nil, value: 'Any Reason' }]
    filters[0][:filterOption]['name'] = 'flagged-for-follow-up'
    tz_offset = 300

    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_2, patient_3, patient_4]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)

    # Check for monitorees who have a specific follow-up flag reason
    filters[0][:value] = 'Lost to Follow-up'
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    filtered_patients_array = [patient_1, patient_4]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients.pluck(:id)
  end

  # --- PATIENTS TABLE DATA TESTS --- #

  test 'patients table data filters out current monitoree' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    exclude_patient = create(:patient, creator: user)
    patient_2 = create(:patient, creator: user)
    patient_3 = create(:patient, creator: user)

    exclude_patient_id = exclude_patient.id
    params = ActionController::Parameters.new({
                                                query: {
                                                  search: '',
                                                  entries: 5,
                                                  workflow: 'global',
                                                  tab: 'all',
                                                  scope: 'all',
                                                  tz_offset: 240,
                                                  exclude_patient_id: exclude_patient_id
                                                }
                                              })

    # Check for monitorees that are HoH or self-reporter
    filtered_patients = patients_table_data(params, user)
    filtered_patients_array = [patient_2, patient_3]
    assert_equal filtered_patients_array.pluck(:id), filtered_patients[:linelist]&.pluck(:id)

    # Check that current monitoree is not in patients list
    patients_by_id = filtered_patients[:linelist]&.pluck(:id)
    assert_not_includes(patients_by_id, exclude_patient_id)
  end

  test 'patients table data returns patients when exclude_patient_id is nil' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    3.times { create(:patient, creator: user) }

    patients = Patient.all

    params = ActionController::Parameters.new({
                                                query: {
                                                  search: '',
                                                  entries: 5,
                                                  workflow: 'global',
                                                  tab: 'all',
                                                  scope: 'all',
                                                  tz_offset: 240
                                                }
                                              })

    # Check that no patients were filtered out
    filtered_patients = patients_table_data(params, user)
    assert_equal patients.pluck(:id), filtered_patients[:linelist]&.pluck(:id)
  end

  test 'patients table data raises InvalidQueryError when exclude_patient_id is not valid' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    3.times { create(:patient, creator: user) }

    params = ActionController::Parameters.new({
                                                query: {
                                                  search: '',
                                                  entries: 5,
                                                  workflow: 'global',
                                                  tab: 'all',
                                                  scope: 'all',
                                                  tz_offset: 240,
                                                  exclude_patient_id: -1
                                                }
                                              })

    # Check bad_request error is thrown
    assert_raises(InvalidQueryError) { patients_table_data(params, user) }
  end

  test 'patients table data filters by assigned user multi-select advanced filter' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    user_1 = create(:public_health_enroller_user)
    user_2 = create(:public_health_enroller_user)
    user_3 = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user)
    patient_1.update_attribute('assigned_user', user_1[:id])
    patient_2 = create(:patient, creator: user)
    patient_2.update_attribute('assigned_user', user_1[:id])
    patient_3 = create(:patient, creator: user)
    patient_3.update_attribute('assigned_user', user_2[:id])
    patient_4 = create(:patient, creator: user)
    patient_4.update_attribute('assigned_user', user_3[:id])

    params = ActionController::Parameters.new({
                                                query: {
                                                  workflow: 'global',
                                                  tab: 'all',
                                                  scope: 'all',
                                                  search: '',
                                                  entries: 25,
                                                  tz_offset: 240,
                                                  filter: [{
                                                    filterOption: {
                                                      name: 'assigned-user',
                                                      title: 'Assigned User (Multi-select)',
                                                      description: 'Monitorees who have a specific assigned user',
                                                      type: 'multi'
                                                    },
                                                    value: [
                                                      { label: user_1[:id], value: user_1[:id] },
                                                      { label: user_2[:id], value: user_2[:id] }
                                                    ]
                                                  }]
                                                }
                                              })
    filtered_patients = patients_table_data(params, user)
    filtered_patients_array = [patient_1, patient_2, patient_3]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients[:linelist]&.pluck(:id)
  end

  test 'patients table data does not filter when nothing selected in multi-select advanced filter' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    patient.update_attribute('assigned_user', user[:id])

    params = ActionController::Parameters.new({
                                                query: {
                                                  workflow: 'global',
                                                  tab: 'all',
                                                  scope: 'all',
                                                  search: '',
                                                  entries: 25,
                                                  tz_offset: 240,
                                                  filter: [{
                                                    filterOption: {
                                                      name: 'assigned-user',
                                                      title: 'Assigned User (Multi-select)',
                                                      description: 'Monitorees who have a specific assigned user',
                                                      type: 'multi'
                                                    },
                                                    value: []
                                                  }]
                                                }
                                              })
    filtered_patients = patients_table_data(params, user)
    filtered_patients_array = [patient]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients[:linelist]&.pluck(:id)
  end

  test 'patients table data filters by jurisdiction multi-select advanced filter' do
    Patient.destroy_all
    user_1 = create(:public_health_enroller_user)
    user_2 = create(:public_health_enroller_user)
    user_3 = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user_1)
    patient_1.update!(jurisdiction_id: user_1[:jurisdiction_id])
    patient_2 = create(:patient, creator: user_1)
    patient_2.update!(jurisdiction_id: user_1[:jurisdiction_id])
    patient_3 = create(:patient, creator: user_2)
    patient_3.update!(jurisdiction_id: user_2[:jurisdiction_id])
    patient_4 = create(:patient, creator: user_3)
    patient_4.update!(jurisdiction_id: user_3[:jurisdiction_id])

    params = ActionController::Parameters.new({
                                                query: {
                                                  workflow: 'global',
                                                  tab: 'all',
                                                  scope: 'all',
                                                  search: '',
                                                  entries: 25,
                                                  tz_offset: 240,
                                                  filter: [{
                                                    filterOption: {
                                                      name: 'jurisdiction',
                                                      title: 'Jurisdiction (Multi-select)',
                                                      description: 'Monitorees of a specific jurisdiction',
                                                      type: 'multi'
                                                    },
                                                    value: [
                                                      { label: user_1[:jurisdiction_id], value: user_1[:jurisdiction_id] }
                                                    ]
                                                  }]
                                                }
                                              })
    filtered_patients = patients_table_data(params, user_1)
    filtered_patients_array = [patient_1, patient_2]
    assert_equal filtered_patients_array.map { |p| p[:id] }, filtered_patients[:linelist]&.pluck(:id)
  end
end
# rubocop:enable Metrics/ClassLength
