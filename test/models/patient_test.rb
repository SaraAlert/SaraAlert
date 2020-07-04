# frozen_string_literal: true

require 'test_case'

class PatientTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create patient' do
    assert create(:patient)
  end

  test 'monitoring open' do
    patient = create(:patient, monitoring: true, purged: false)
    assert_equal 1, Patient.monitoring_open.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: false)
    assert_equal 0, Patient.monitoring_open.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: true)
    assert_equal 0, Patient.monitoring_open.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: true)
    assert_equal 0, Patient.monitoring_open.where(id: patient.id).count
  end

  test 'monitoring closed' do
    patient = create(:patient, monitoring: false)
    assert_equal 1, Patient.monitoring_closed.where(id: patient.id).count

    patient = create(:patient, monitoring: true)
    assert_equal 0, Patient.monitoring_closed.where(id: patient.id).count
  end

  test 'monitoring closed without purged' do
    patient = create(:patient, monitoring: false, purged: false)
    assert_equal 1, Patient.monitoring_closed_without_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false)
    assert_equal 0, Patient.monitoring_closed_without_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: true)
    assert_equal 0, Patient.monitoring_closed_without_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: true)
    assert_equal 0, Patient.monitoring_closed_without_purged.where(id: patient.id).count
  end

  test 'monitoring closed with purged' do
    patient = create(:patient, monitoring: false, purged: true)
    assert_equal 1, Patient.monitoring_closed_with_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false)
    assert_equal 0, Patient.monitoring_closed_with_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: true)
    assert_equal 0, Patient.monitoring_closed_with_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: false)
    assert_equal 0, Patient.monitoring_closed_with_purged.where(id: patient.id).count
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

  test 'purged' do
    patient = create(:patient, purged: false)
    assert_equal 0, Patient.purged.where(id: patient.id).count

    patient = create(:patient, purged: true)
    assert_equal 1, Patient.purged.where(id: patient.id).count
  end

  test 'confirmed case' do
    patient = create(:patient, monitoring_reason: 'Case confirmed')
    assert_equal 1, Patient.confirmed_case.where(id: patient.id).count

    patient = create(:patient, monitoring_reason: 'Completed Monitoring')
    assert_equal 0, Patient.confirmed_case.where(id: patient.id).count

    patient = create(:patient)
    assert_equal 0, Patient.confirmed_case.where(id: patient.id).count
  end

  test 'exposure pui' do
    patient = create(:patient, monitoring: true, purged: false, isolation: false, public_health_action: 'Recommended laboratory testing')
    verify_patient_status_scopes(patient, :exposure_under_investigation)
  end

  test 'exposure symptomatic' do
    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None')
    create(:assessment, patient: patient, symptomatic: true)
    verify_patient_status_scopes(patient, :exposure_symptomatic)

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 25.hours.ago)
    verify_patient_status_scopes(patient, :exposure_symptomatic)
  end

  test 'exposure non reporting' do
    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    verify_patient_status_scopes(patient, :exposure_non_reporting)

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
    verify_patient_status_scopes(patient, :exposure_non_reporting)
  end

  test 'exposure asymptomatic' do
    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None')
    verify_patient_status_scopes(patient, :exposure_asymptomatic)

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: false)
    verify_patient_status_scopes(patient, :exposure_asymptomatic)
  end

  test 'isolation test based' do
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true)

    # meets definition: has at least 1 assessment and 2 negative test results
    create(:assessment, patient: patient, created_at: 50.days.ago)
    create(:laboratory, patient: patient, result: 'negative', specimen_collection: 50.days.ago)
    create(:laboratory, patient: patient, result: 'negative', specimen_collection: 50.days.ago)
    verify_patient_status_scopes(patient, :isolation_test_based)
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: no assessments
    create(:laboratory, patient: patient, result: 'negative')
    create(:laboratory, patient: patient, result: 'negative')
    verify_patient_status_scopes(patient, :isolation_reporting)
    Laboratory.destroy_all

    # does not meet definition: only 1 negative test result
    create(:assessment, patient: patient)
    create(:laboratory, patient: patient, result: 'negative')
    verify_patient_status_scopes(patient, :isolation_reporting)
    Assessment.destroy_all
    Laboratory.destroy_all
  end

  test 'isolation symp non test based' do
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 14.days.ago, symptom_onset: 12.days.ago)

    # meets definition: assessment older than 72 hours
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    verify_patient_status_scopes(patient, :isolation_symp_non_test_based)
    Assessment.destroy_all

    # meets definition: had an assessment with no fever
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, created_at: 70.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: false)
    verify_patient_status_scopes(patient, :isolation_symp_non_test_based)
    Assessment.destroy_all

    # meets definition: had a fever more than 72 hours ago
    assessment = create(:assessment, patient: patient, created_at: 80.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: true)
    verify_patient_status_scopes(patient, :isolation_symp_non_test_based)
    Assessment.destroy_all

    # does not meet definition: assessment not older than 72 hours
    create(:assessment, patient: patient, created_at: 70.hours.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all

    # does not meet definition: had a fever within the past 72 hours
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, created_at: 70.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: true)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all

    # does not meet definition: used a fever reducer within the past 72 hours
    create(:assessment, patient: patient, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, created_at: 70.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'used-a-fever-reducer', bool_value: true)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all
  end

  test 'isolation asymp non test based' do
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 14.days.ago)

    # meets definition: asymptomatic after positive test result
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 15.days.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 8.days.ago)
    verify_patient_status_scopes(patient, :isolation_asymp_non_test_based)
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic before positive test result but not afterwards
    create(:assessment, patient: patient, symptomatic: true, created_at: 12.days.ago)
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 11.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet defiition: has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 8.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Laboratory.destroy_all

    # does not meet defiition: has positive test result more than 10 days ago, but also has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 11.days.ago)
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 9.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Laboratory.destroy_all

    # does not meet defiition: has negative test result more than 10 days ago, but also has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'negative', specimen_collection: 11.days.ago)
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 9.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Laboratory.destroy_all

    # does not meet defiition: has positive test result more than 10 days ago, but also has positive test result less than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 11.days.ago)
    create(:laboratory, patient: patient, result: 'negative', specimen_collection: 9.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 15.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 8.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 13.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 12.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 12.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 6.days.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 5.days.ago)
    create(:laboratory, patient: patient, result: 'negative', specimen_collection: 3.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all
    Laboratory.destroy_all

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    create(:laboratory, patient: patient, result: 'positive', specimen_collection: 15.days.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 14.days.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 13.days.ago)
    create(:laboratory, patient: patient, result: 'negative', specimen_collection: 12.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all
    Laboratory.destroy_all
  end

  test 'isolation non reporting' do
    # patient was created more than 24 hours ago with no assessments
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 2.days.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)

    # patient has asymptomatic assessment more than 24 hours ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all

    # patient has symptomatic assessment more than 24 hours ago
    create(:assessment, patient: patient, symptomatic: true, created_at: 28.hours.ago)
    verify_patient_status_scopes(patient, :isolation_non_reporting)
    Assessment.destroy_all
  end

  test 'isolation reporting' do
    # patient was created less than 24 hours ago
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 16.hours.ago)
    verify_patient_status_scopes(patient, :isolation_reporting)

    # patient has asymptomatic assessment less than 24 hours ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 10.hours.ago)
    verify_patient_status_scopes(patient, :isolation_reporting)
    Assessment.destroy_all

    # patient has symptomatic assessment less than 24 hours ago
    create(:assessment, patient: patient, symptomatic: true, created_at: 18.hours.ago)
    verify_patient_status_scopes(patient, :isolation_reporting)
    Assessment.destroy_all
  end

  test 'address timezone offset' do
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

  def verify_patient_status_scopes(patient, status)
    patients = Patient.where(id: patient.id)

    assert patients.symptomatic.exists? if status == :exposure_symptomatic
    assert patients.non_reporting.exists? if status == :exposure_non_reporting
    assert patients.asymptomatic.exists? if status == :exposure_asymptomatic

    assert_equal status == :purged, patients.purged.exists?
    assert_equal status == :closed, patients.monitoring_closed_without_purged.exists?

    assert_equal status == :exposure_symptomatic, patients.exposure_symptomatic.exists?
    assert_equal status == :exposure_non_reporting, patients.exposure_non_reporting.exists?
    assert_equal status == :exposure_asymptomatic, patients.exposure_asymptomatic.exists?
    assert_equal status == :exposure_under_investigation, patients.exposure_under_investigation.exists?

    assert_equal status == :isolation_asymp_non_test_based, patients.isolation_asymp_non_test_based.exists?
    assert_equal status == :isolation_symp_non_test_based, patients.isolation_symp_non_test_based.exists?
    assert_equal status == :isolation_test_based, patients.isolation_test_based.exists?

    isolation_requiring_review = %i[isolation_asymp_non_test_based isolation_symp_non_test_based isolation_test_based].include?(status)
    assert_equal isolation_requiring_review, patients.isolation_requiring_review.exists?

    assert_equal status == :isolation_reporting, patients.isolation_reporting.exists?
    assert_equal status == :isolation_non_reporting, patients.isolation_non_reporting.exists?

    assert_equal status, patient.status
  end
end
