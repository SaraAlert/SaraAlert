# frozen_string_literal: true

require 'test_case'

class CloseContactTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  def valid_cc
    CloseContact.new(
      patient_id: 1,
      first_name: 'Domingo54',
      last_name: 'Boehm62',
      primary_telephone: '+15555550111',
      email: 'jeremy@example.com',
      contact_attempts: 3,
      last_date_of_exposure: 20.days.ago,
      assigned_user: 8,
      notes: 'Only the educated are free.',
      enrolled_id: 3
    )
  end

  test 'update patient updated_at upon close_contact create, update, and delete' do
    patient = create(:patient)

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    close_contact = create(:close_contact, patient: patient)
    assert_in_delta patient.updated_at, Time.now.utc, 1

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    close_contact.update(contact_attempts: 2)
    assert_in_delta patient.updated_at, Time.now.utc, 1

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    close_contact.destroy
    assert_in_delta patient.updated_at, Time.now.utc, 1
  end

  test 'validates primary phone is a possible phone number in api context' do
    cc = valid_cc

    cc.primary_telephone = '+15555555555'
    assert cc.valid?(:api)

    cc.primary_telephone = '+1 555 555 5555'
    assert cc.valid?(:api)

    cc.primary_telephone = ''
    assert cc.valid?(:api)

    cc.primary_telephone = nil
    assert cc.valid?(:api)

    cc.primary_telephone = '+1 123 456 7890'
    assert_not cc.valid?(:api)

    cc.primary_telephone = '123'
    assert_not cc.valid?(:api)
    assert cc.valid?
  end

  test 'validates email is a valid email address in api and import context' do
    cc = valid_cc

    cc.email = 'foo@bar.com'
    assert cc.valid?(:api)

    cc.email = ''
    assert cc.valid?(:api)

    cc.email = nil
    assert cc.valid?(:api)

    cc.email = 'not@an@email.com'
    assert_not cc.valid?(:api)
    assert cc.valid?
  end

  test 'validates assigned user is valid in api context' do
    cc = valid_cc

    cc.assigned_user = 1
    assert cc.valid?(:api)

    cc.assigned_user = 999_999
    assert cc.valid?(:api)

    cc.assigned_user = nil
    assert cc.valid?(:api)

    cc.assigned_user = 0
    assert_not cc.valid?(:api)
    assert cc.valid?
  end

  test 'validates contact_attempts is valid in api context' do
    cc = valid_cc

    cc.contact_attempts = 0
    assert cc.valid?(:api)

    cc.contact_attempts = 1
    assert cc.valid?(:api)

    cc.contact_attempts = nil
    assert cc.valid?(:api)

    cc.contact_attempts = -1
    assert_not cc.valid?(:api)
    assert cc.valid?
  end

  test 'validates last_date_of_exposure is a valid date in api context' do
    cc = valid_cc

    cc.last_date_of_exposure = 25.years.ago
    assert cc.valid?(:api)

    cc.last_date_of_exposure = '01-15-2000'
    assert_not cc.valid?(:api)

    cc.last_date_of_exposure = '2000-13-13'
    assert_not cc.valid?(:api)
    assert cc.valid?
  end

  test 'validates a complete close contact is present in api context' do
    cc = valid_cc

    cc.first_name = nil
    cc.last_name = nil
    assert_not cc.valid?(:api)
    assert cc.valid?

    cc = valid_cc
    cc.primary_telephone = nil
    cc.email = nil
    assert_not cc.valid?(:api)
    assert cc.valid?
  end
end
