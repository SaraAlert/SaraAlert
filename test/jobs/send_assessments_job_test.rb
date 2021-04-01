# frozen_string_literal: true

require 'test_case'

class SendAssessmentsJobTest < ActiveSupport::TestCase
  def setup
    Timecop.freeze(Time.now.in_time_zone('Eastern Time (US & Canada)').change(hour: 10).utc)
    Patient.delete_all
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
    ActionMailer::Base.deliveries.clear
  end

  def teardown; end

  def default_days_ago(days)
    (Time.now.in_time_zone('Eastern Time (US & Canada)') - days.days)
  end

  test 'send assessments job to zero patients' do
    email = SendAssessmentsJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')

    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, 'Total eligible for notifications at runtime: 0')
    assert_includes(email_body, 'Sent during this job run: 0')
    assert_includes(email_body, 'Not sent during this job run (due to exceptions): 0')
  end

  test 'send assessments job with StandardError exceptions' do
    # https://relishapp.com/rspec/rspec-mocks/docs/working-with-legacy-code/any-instance
    # https://relishapp.com/rspec/rspec-mocks/docs/configuring-responses/raising-an-error
    allow_any_instance_of(Patient).to receive(:send_assessment).and_raise('Testing send_assessments_job')

    # Patients that should be sent assessments
    # But will not be sent since we are forcing an exception
    eligible_patients = [
      { isolation: true },
      { preferred_contact_method: 'SMS Texted Weblink', continuous_exposure: true },
      { preferred_contact_method: 'Telephone call', last_date_of_exposure: nil, created_at: default_days_ago(5) },
      { preferred_contact_method: 'SMS Text-message', last_date_of_exposure: default_days_ago(5), created_at: default_days_ago(5) },
      { last_date_of_exposure: default_days_ago(11), created_at: default_days_ago(20) }
    ].map do |eligible_params|
      create(
        :patient,
        {
          email: 'example@example.com',
          preferred_contact_method: 'E-mailed Web Link',
          preferred_contact_time: 'Morning',
          last_date_of_exposure: 1.day.ago,
          submission_token: SecureRandom.urlsafe_base64[0, 10]
        }.merge(eligible_params)
      )
    end

    email = SendAssessmentsJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')

    assert_includes(email_body, "Total eligible for notifications at runtime: #{eligible_patients.size}")
    assert_includes(email_body, 'Sent during this job run: 0')
    assert_includes(email_body, "Not sent during this job run (due to exceptions): #{eligible_patients.size}")

    eligible_patients.each do |patient|
      assert_includes(email_body, "#{patient.id}, #{patient.preferred_contact_method}, Testing send_assessments_job")
    end
  end

  test 'send assessments job to various patient configurations' do
    # Patients that should NOT be sent assessments or be counted in
    # any of the counts found in the summary email
    ineligible_patients = [
      { purged: true },
      { pause_notifications: true },
      { preferred_contact_method: 'Unknown' },
      { preferred_contact_method: 'Opt-out' },
      { preferred_contact_method: '' },
      { preferred_contact_method: nil },
      { monitoring: false },
      { last_assessment_reminder_sent: Time.now }
    ].map do |ineligible_params|
      create(
        :patient,
        {
          email: 'example@example.com',
          preferred_contact_method: 'E-mailed Web Link',
          preferred_contact_time: 'Morning',
          last_date_of_exposure: 1.day.ago,
          submission_token: SecureRandom.urlsafe_base64[0, 10]
        }.merge(ineligible_params)
      )
    end

    # Patients that are expected to be returned by the scope but are not
    # expected to be sent assessments
    # (due to any logic in the Patient#send_assessment method)
    #
    # NOTE: Expect to need to move items from this list to the ineligible list
    #       above as logic is pulled out of send_assessment and into reminder_eligible
    scope_not_sent = [
      { last_date_of_exposure: nil, created_at: 50.days.ago },
      { last_date_of_exposure: 50.days.ago, created_at: 50.days.ago },
      { latest_assessment_at: Time.now },
      { preferred_contact_time: 'Evening' }
    ].map do |ineligible_params|
      create(
        :patient,
        {
          email: 'example@example.com',
          preferred_contact_method: 'E-mailed Web Link',
          preferred_contact_time: 'Morning',
          last_date_of_exposure: 1.day.ago,
          submission_token: SecureRandom.urlsafe_base64[0, 10]
        }.merge(ineligible_params)
      )
    end

    # Patients that should be sent assessments
    eligible_patients = [
      { isolation: true },
      { preferred_contact_method: 'SMS Texted Weblink', continuous_exposure: true },
      { preferred_contact_method: 'Telephone call', last_date_of_exposure: nil, created_at: default_days_ago(5) },
      { preferred_contact_method: 'SMS Text-message', last_date_of_exposure: default_days_ago(5), created_at: default_days_ago(5) },
      { last_date_of_exposure: default_days_ago(11), created_at: default_days_ago(20) }
    ].map do |eligible_params|
      create(
        :patient,
        {
          email: 'example@example.com',
          preferred_contact_method: 'E-mailed Web Link',
          preferred_contact_time: 'Morning',
          last_date_of_exposure: 1.day.ago,
          submission_token: SecureRandom.urlsafe_base64[0, 10]
        }.merge(eligible_params)
      )
    end

    email = SendAssessmentsJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')

    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, "Total eligible for notifications at runtime: #{eligible_patients.size + scope_not_sent.size}")
    assert_includes(email_body, "Sent during this job run: #{eligible_patients.size}")
    assert_includes(email_body, 'Not sent during this job run (due to exceptions): 0')
    eligible_patients.each do |patient|
      assert_includes(email_body, "#{patient.id}, #{patient.preferred_contact_method}")
    end
    scope_not_sent.each do |patient|
      assert_not_includes(email_body, "#{patient.id}, #{patient.preferred_contact_method}")
    end
    ineligible_patients.each do |patient|
      assert_not_includes(email_body, "#{patient.id}, #{patient.preferred_contact_method}")
    end
  end
end
