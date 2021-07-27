# frozen_string_literal: true

require 'test_case'

class ClosePatientsJobTest < ActiveSupport::TestCase
  def setup
    # Variable's purpose is strictly to reduce line size
    @period = ADMIN_OPTIONS['monitoring_period_days']
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
    ENV['TWILLIO_STUDIO_FLOW'] = 'TEST'
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    ADMIN_OPTIONS['job_run_email'] = nil
    ENV['TWILLIO_STUDIO_FLOW'] = nil
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
    assert_histories_contain(patient, "Monitoree has completed monitoring. Reason: Enrolled more than #{@period} days after last date of exposure (system)")
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
    assert_histories_contain(patient, 'Monitoree has completed monitoring. Reason: Completed Monitoring (system)')
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
    assert_equal(updated_patient.monitoring_reason, "Enrolled more than #{@period} days after last date of exposure (system)")
    assert_histories_contain(patient, "Monitoree has completed monitoring. Reason: Enrolled more than #{@period} days after last date of exposure (system)")
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
    assert_histories_contain(patient, 'Monitoree has completed monitoring. Reason: Enrolled on last day of monitoring period (system)')
  end

  test 'sends closed email if closed record is a reporter' do
    Patient.destroy_all
    patient = create(:patient,
                     first_name: 'Jon',
                     last_name: 'Doe',
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago,
                     email: 'testpatient@example.com',
                     preferred_contact_method: 'E-mailed Web Link',
                     created_at: 20.days.ago)

    ClosePatientsJob.perform_now
    assert_not_nil(ActionMailer::Base.deliveries.find { |d| d.to.include? 'test@test.com' })
    closed_email = ActionMailer::Base.deliveries.find { |d| d.to.include? 'testpatient@example.com' }
    assert_not_nil closed_email
    assert_equal(closed_email.header['subject'].value, 'Sara Alert Reporting Complete')
    assert_includes(
      closed_email.text_part.body.to_s.gsub("\r", ' ').gsub("\n", ' '),
      "Sara Alert monitoring for #{patient.initials_age('-')} completed on #{DateTime.now.strftime('%m-%d-%Y')}! Thank you for your participation."
    )
    assert_equal(closed_email.to[0], patient.email)
    assert_histories_contain(patient, 'Monitoring Complete message was sent.')
    assert_not_histories_contain(patient, 'because the monitoree email was blank.')
    assert_histories_contain(patient, 'Monitoree has completed monitoring. Reason: Completed Monitoring (system)')
  end

  test 'does not send closed notification if jurisdiction send_close is false' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago,
                     email: 'testpatient@example.com',
                     preferred_contact_method: 'E-mailed Web Link')
    patient.jurisdiction.update(send_close: false)
    ClosePatientsJob.perform_now
    assert_equal(ActionMailer::Base.deliveries.count, 1)
    assert_histories_contain(patient, "Monitoree has completed monitoring. Reason: Enrolled more than #{@period} days after last date of exposure (system)")
  end

  ['Telephone call', 'Opt-out', 'Unknown', nil, ''].each do |preferred_contact_method|
    test "no email notification for unsupported preferred contact method #{preferred_contact_method || 'nil'}" do
      patient = create(:patient,
                       purged: false,
                       isolation: false,
                       monitoring: true,
                       symptom_onset: nil,
                       public_health_action: 'None',
                       latest_assessment_at: Time.now,
                       last_date_of_exposure: 20.days.ago,
                       email: 'testpatient@example.com',
                       preferred_contact_method: preferred_contact_method,
                       created_at: 20.days.ago)

      ClosePatientsJob.perform_now
      history_friendly_method = patient.preferred_contact_method.blank? ? patient.preferred_contact_method : 'Unknown'
      assert_histories_contain(patient, "#{history_friendly_method}, is not supported for this message type.")
      assert_histories_contain(patient, 'Monitoree has completed monitoring. Reason: Completed Monitoring (system)')
    end
  end

  ['SMS Texted Weblink', 'SMS Text-message', 'E-mailed Web Link'].each do |preferred_contact_method|
    test "does not send closed notification if #{preferred_contact_method} preferred and field is blank" do
      patient = create(:patient,
                       purged: false,
                       isolation: false,
                       monitoring: true,
                       symptom_onset: nil,
                       public_health_action: 'None',
                       latest_assessment_at: Time.now,
                       last_date_of_exposure: 20.days.ago,
                       preferred_contact_method: preferred_contact_method,
                       created_at: 20.days.ago)

      ClosePatientsJob.perform_now
      method_text = preferred_contact_method == 'E-mailed Web Link' ? 'email' : 'primary phone number'
      assert_histories_contain(patient, "because their preferred contact method, #{method_text}, was blank.")
      assert_histories_contain(patient, 'Monitoree has completed monitoring. Reason: Completed Monitoring (system)')
    end

    test "sends closed email if closed record is a reporter with #{preferred_contact_method} preferred" do
      patient = create(:patient,
                       purged: false,
                       isolation: false,
                       monitoring: true,
                       symptom_onset: nil,
                       public_health_action: 'None',
                       latest_assessment_at: Time.now,
                       last_date_of_exposure: 20.days.ago,
                       email: 'testpatient@example.com',
                       primary_telephone: '+12223334444',
                       preferred_contact_method: preferred_contact_method,
                       created_at: 20.days.ago)

      ClosePatientsJob.perform_now
      method_text = preferred_contact_method == 'E-mailed Web Link' ? 'email' : 'primary phone number'
      assert_not_histories_contain(patient, "because their preferred contact method, #{method_text}, was blank.")
      assert_histories_contain(patient, 'Monitoree has completed monitoring. Reason: Completed Monitoring (system)')
      assert_histories_contain(patient, 'Monitoring Complete message was sent.')
    end
  end

  ['SMS Texted Weblink', 'SMS Text-message'].each do |preferred_contact_method|
    test "does not send closed notification if SMS is blocked and preferred_contact_method is #{preferred_contact_method}" do
      patient = create(:patient,
                       purged: false,
                       isolation: false,
                       monitoring: true,
                       symptom_onset: nil,
                       public_health_action: 'None',
                       latest_assessment_at: Time.now,
                       last_date_of_exposure: 20.days.ago,
                       preferred_contact_method: preferred_contact_method,
                       primary_telephone: '+12223334444',
                       created_at: 20.days.ago)
      BlockedNumber.create(phone_number: patient.primary_telephone)
      ClosePatientsJob.perform_now
      method_text = preferred_contact_method == 'E-mailed Web Link' ? 'email' : 'primary phone number'
      assert_histories_contain(
        patient,
        'The system was unable to send a monitoring complete message to this monitoree'\
        ' because the recipient phone number blocked communication with Sara Alert'
      )
      assert_not_histories_contain(patient, "because their preferred contact method, #{method_text}, was blank.")
      assert_histories_contain(patient, 'Monitoree has completed monitoring. Reason: Completed Monitoring (system)')
    end
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
