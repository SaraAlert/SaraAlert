# frozen_string_literal: true

require 'test_case'

class PatientQueryHelperTest < ActionView::TestCase
  test 'advanced filter close contact with known case id exact match' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    create(:patient, creator: user, contact_of_known_case_id: '234')
    patient_2 = create(:patient, creator: user, contact_of_known_case_id: '23')
    create(:patient, creator: user, contact_of_known_case_id: '34')

    patients = Patient.all
    filters = [{ filterOption: {}, additionalFilterOption: 'Exact Match', value: '23' }]
    filters[0][:filterOption]['name'] = 'close-contact-with-known-case-id'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    assert_equal [patient_2].map { |p| p[:id] }, filtered_patients.pluck(:id)
  end

  test 'advanced filter close contact with known case id contains' do
    Patient.destroy_all
    user = create(:public_health_enroller_user)
    patient_1 = create(:patient, creator: user, contact_of_known_case_id: '234')
    patient_2 = create(:patient, creator: user, contact_of_known_case_id: '23')
    create(:patient, creator: user, contact_of_known_case_id: '34')

    patients = Patient.all
    filters = [{ filterOption: {}, additionalFilterOption: 'Contains', value: '23' }]
    filters[0][:filterOption]['name'] = 'close-contact-with-known-case-id'
    tz_offset = 300
    filtered_patients = advanced_filter(patients, filters, tz_offset)
    assert_equal [patient_1, patient_2].map { |p| p[:id] }, filtered_patients.pluck(:id)
  end
end
