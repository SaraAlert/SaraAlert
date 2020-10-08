# frozen_string_literal: true

require 'test_case'

class ClosePatientsJobTest < ActiveSupport::TestCase
  def setup
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    ADMIN_OPTIONS['job_run_email'] = nil
  end

  test 'handles case where last date of exposure is nil' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: nil,
                     created_at: 20.days.ago)
    ClosePatientsJob.perform_now
    # Reload attributes after job
    patient.reload
    assert_equal('Completed Monitoring (system)', patient.monitoring_reason)
  end

  test 'updates appropriate fields on each closed record' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    ClosePatientsJob.perform_now

    # Verify fields changed
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.closed_at.to_date, DateTime.now.to_date)
    assert_equal(updated_patient.monitoring, false)
  end

  test 'creates expected History item for each record' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    ClosePatientsJob.perform_now
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.histories.last.history_type, History::HISTORY_TYPES[:record_automatically_closed])
  end

  test 'creates correct monitoring reason when record has normally completed monitoring period' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago,
                     created_at: 7.days.ago)

    ClosePatientsJob.perform_now
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.monitoring_reason, 'Completed Monitoring (system)')
  end

  test 'creates correct monitoring reason when record was enrolled past their monitoring period' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago,
                     created_at: Time.now)

    ClosePatientsJob.perform_now
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.monitoring_reason, 'Enrolled more than 14 days after last date of exposure (system)')
  end

  test 'creates correct monitoring reason when record was enrolled on their last day of monitoring' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 14.days.ago,
                     created_at: Time.now)

    ClosePatientsJob.perform_now
    updated_patient = Patient.find_by(id: patient.id)
    assert_equal(updated_patient.monitoring_reason, 'Enrolled on last day of monitoring period (system)')
  end

  test 'sends closed email if closed record is a reporter' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago,
                     email: 'testpatient@example.com')

    ClosePatientsJob.perform_now
    assert_equal(ActionMailer::Base.deliveries.count, 2)
    close_email = ActionMailer::Base.deliveries[-2]
    assert_includes(close_email.to_s, 'Sara Alert Reporting Complete')
    assert_equal(close_email.to[0], patient.email)
  end

  test 'sends an admin email with all closed monitorees' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)
    email = ClosePatientsJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, patient.id.to_s)
  end

  test 'sends an admin email with all monitorees not closed due to an exception' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    allow_any_instance_of(Patient).to(receive(:save!) do
      raise StandardError, 'Test StandardError'
    end)

    email = ClosePatientsJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, patient.id.to_s)
    assert_includes(email_body, 'Test StandardError')
  end
end
