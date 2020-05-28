# frozen_string_literal: true

require 'test_case'

class PatientTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create patient' do
    assert create(:patient)
  end

  test 'purge eligible' do
    jur = Jurisdiction.create
    user = User.create!(
      email: 'foobar@example.com',
      password: '1234567ab!',
      jurisdiction: jur,
      force_password_change: true # Require user to change password on first login
    )
    Patient.destroy_all
    patient = Patient.new(creator: user, jurisdiction: jur)
    patient.responder = patient
    patient.save
    assert Patient.count == 1
    # Updated at of today, still monitoring, should not be purgeable
    assert Patient.purge_eligible.count.zero?
    patient.update!(monitoring: false)
    # Updated at of today, not monitoring, should not be purgeable
    assert Patient.purge_eligible.count.zero?
    # Updated at of 2x purgeable_after, not monitoring, should obviously be purgeable regardless of weekly_purge_date and weekly_purge_warning_date
    patient.update!(updated_at: (2 * ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.count == 1
    # ADMIN_OPTIONS['weekly_purge_warning_date'] is 2.5 days before ADMIN_OPTIONS['weekly_purge_date']
    # Test if the email was going out in 1 minute and patient was updated purgeable_after minutes ago, patient should be purgeable
    # These tests reset the weekly_purge_warning_date and weekly_purge_date, and set the times to 1 minute from Time.now to avoid timing issues
    # caused by the duration of time it takes to run the test
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 2.5.days + 1.minute).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.count == 1
    # However, if the test email was going out in 1 minute from now and the patient was last updated purgeable_after - 2 minutes ago, no purge
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 2.5.days + 1.minute).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'] - 2).minutes.ago)
    assert Patient.purge_eligible.count.zero?
    # Now test the boundry conditions that exist between the purge_warning and the purging
    # ADMIN_OPTIONS['weekly_purge_warning_date'] is 2.5 days before ADMIN_OPTIONS['weekly_purge_date']
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    # If the email is going out in 1 minute, and the patient was modified purgeable_after minutes ago, they should not be purgeable
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.count.zero?
    # However, if the email is going out in 1 minute and the patient was modified right before the warning (2.5 days ago), they should be purgeable
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'] + (2.5.days / 1.minute)).minutes.ago)
    assert Patient.purge_eligible.count == 1
    # Anything less than the 2.5 days ago means the patient was modified between the warning and the purging and should not be purged
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'] + (2.5.days / 1.minute) - 2).minutes.ago)
    assert Patient.purge_eligible.count.zero?
  end

  test 'asymp non test based' do
    # setup
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true)
    assert_equal 1, Patient.count
    assert_equal 0, Patient.asymp_non_test_based.count

    # meets definition: asymptomatic after positive test result
    Laboratory.create(patient_id: patient.id, result: 'positive', report: 15.days.ago)
    Assessment.create(patient_id: patient.id, symptomatic: false, created_at: 8.days.ago)
    assert_equal 1, Patient.asymp_non_test_based.count
    Laboratory.destroy_all
    Assessment.destroy_all

    # meets definition: only symptomatic before positive test result but not afterwards
    Laboratory.create(patient_id: patient.id, result: 'positive', report: 11.days.ago)
    Assessment.create(patient_id: patient.id, symptomatic: true, created_at: 12.days.ago)
    assert_equal 1, Patient.asymp_non_test_based.count
    Laboratory.destroy_all
    Assessment.destroy_all

    # does not meet defiition: has positive test result less than 10 days ago
    Laboratory.create(patient_id: patient.id, result: 'positive', report: 8.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.count
    Laboratory.destroy_all

    # does not meet defiition: has positive test result more than 10 days ago, but also has positive test result less than 10 days ago
    Laboratory.create(patient_id: patient.id, result: 'positive', report: 11.days.ago)
    Laboratory.create(patient_id: patient.id, result: 'positive', report: 9.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.count
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result
    Laboratory.create(patient_id: patient.id, result: 'positive', report: 15.days.ago)
    Assessment.create(patient_id: patient.id, symptomatic: true, created_at: 8.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.count
    Laboratory.destroy_all
    Assessment.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    Laboratory.create(patient_id: patient.id, result: 'positive', report: 13.days.ago)
    Assessment.create(patient_id: patient.id, symptomatic: true, created_at: 12.days.ago)
    assert_equal 0, Patient.asymp_non_test_based.count
    Laboratory.destroy_all
    Assessment.destroy_all
  end

  test 'get timezone offset' do
    jur = Jurisdiction.create
    user = User.create!(
      email: 'foobar@example.com',
      password: '1234567ab!',
      jurisdiction: jur,
      force_password_change: true # Require user to change password on first login
    )
    Patient.destroy_all
    patient = Patient.new(creator: user, jurisdiction: jur)
    patient.responder = patient
    patient.save
    assert patient.address_timezone_offset == '-04:00'
    patient.update(address_state: 'California')
    assert patient.address_timezone_offset == '-07:00'
    patient.update(monitored_address_state: 'Northern Mariana Islands')
    assert patient.address_timezone_offset == '+10:00'
  end
end
