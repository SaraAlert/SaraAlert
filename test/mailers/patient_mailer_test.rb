# frozen_string_literal: true

require 'test_case'

class PatientMailerTest < ActionMailer::TestCase
  def setup
    @patient = create(:patient_with_submission_token,
                      email: 'test@example.com')

    @previous_job_run_email = ADMIN_OPTIONS['job_run_email']
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
  end

  def teardown
    ADMIN_OPTIONS['job_run_email'] = @previous_job_run_email
  end

  %i[enrollment_email assessment_email closed_email].each do |mthd|
    test "#{mthd} no email provided" do
      @patient.update(email: nil)
      email = PatientMailer.send(mthd, @patient)
      assert_equal '', email.body
      assert_nil email.to
      assert_nil email.from
      assert_nil email.deliver_now
    end
  end

  test 'enrollment email with dependents' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.urlsafe_base64[0, 10])
    email = PatientMailer.enrollment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_includes email_body, dependent.submission_token

    dependent.update(monitoring: false)
    email = PatientMailer.enrollment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_not_includes email_body, dependent.submission_token
  end

  test 'enrollment email creates a welcome message sent history' do
    assert_difference '@patient.histories.length', 1 do
      PatientMailer.enrollment_email(@patient).deliver_now
      assert_not ActionMailer::Base.deliveries.empty?
      @patient.reload
      assert_equal 'Welcome Message Sent', @patient.histories.first.history_type
    end
  end

  Languages.all_languages.filter { |_k, v| v[:supported].present? }.each_key do |language|
    test "assessment email contents in #{language}" do
      @patient.update(primary_language: language.to_s)
      email = PatientMailer.assessment_email(@patient).deliver_now
      email_body = email.parts.first.body.to_s.tr("\n", ' ').tr("\r", '')
      assert_not ActionMailer::Base.deliveries.empty?
      assert_equal [@patient.email], email.to
      assert_equal [PatientMailer.default[:from]], email.from
      lang = Languages.supported_language?(@patient.primary_language, :email) ? @patient.primary_language : 'eng'
      assert_equal I18n.t('assessments.html.email.reminder.subject', locale: lang), email.subject
      assert_includes email_body, I18n.t('assessments.html.email.reminder.header', locale: lang)
      assert_includes email_body, I18n.t('assessments.html.email.shared.greeting', locale: lang, name: @patient&.initials_age('-'))
      assert_includes email_body.strip, I18n.t('assessments.html.email.reminder.thank_you', locale: lang)
      assert_includes email_body, I18n.t('assessments.html.email.shared.report', locale: lang)
      assert_includes email_body, I18n.t('assessments.html.email.shared.footer', locale: lang)
    end

    test "closed email contents in #{language}" do
      @patient.update(primary_language: language.to_s, closed_at: DateTime.now)
      email = PatientMailer.closed_email(@patient).deliver_now
      email_body = email.parts.first.body.to_s.tr("\n", ' ').tr("\r", '')
      assert_not ActionMailer::Base.deliveries.empty?
      assert_equal [@patient.email], email.to
      assert_equal [PatientMailer.default[:from]], email.from
      lang = Languages.supported_language?(@patient.primary_language, :email) ? @patient.primary_language : 'eng'
      assert_equal I18n.t('assessments.html.email.closed.subject', locale: lang), email.subject
      assert_includes email_body, I18n.t('assessments.html.email.closed.header', locale: lang)
      assert_includes email_body, I18n.t(
        'assessments.html.email.closed.thank_you',
        initials_age: @patient.initials_age('-'),
        completed_date: @patient.closed_at.strftime('%m-%d-%Y'),
        locale: lang
      )
      assert_includes email_body, I18n.t('assessments.html.email.shared.footer', locale: lang)
      assert_histories_contain(@patient, 'Monitoring Complete message was sent.')
    end

    test "enrollment email contents in #{language}" do
      @patient.update(primary_language: language.to_s)
      email = PatientMailer.enrollment_email(@patient).deliver_now
      email_body = email.parts.first.body.to_s.tr("\n", ' ').tr("\r", '')
      assert_not ActionMailer::Base.deliveries.empty?
      assert_equal [@patient.email], email.to
      assert_equal [PatientMailer.default[:from]], email.from
      lang = Languages.supported_language?(@patient.primary_language, :email) ? @patient.primary_language : 'eng'
      assert_equal I18n.t('assessments.html.email.enrollment.subject', locale: lang), email.subject
      assert_includes email_body, I18n.t('assessments.html.email.enrollment.header', locale: lang)
      assert_includes email_body, I18n.t('assessments.html.email.shared.greeting', locale: lang, name: @patient&.initials_age('-'))
      assert_includes email_body, I18n.t('assessments.html.email.enrollment.info1', locale: lang)
      assert_includes email_body, I18n.t('assessments.html.email.enrollment.info2', locale: lang)
      assert_includes email_body, I18n.t('assessments.html.email.shared.report', locale: lang)
      assert_includes email_body, I18n.t('assessments.html.email.shared.footer', locale: lang)
    end
  end

  test 'assessment email history and reminder' do
    @patient.update(preferred_contact_method: 'E-mailed Web Link')
    assert_difference '@patient.histories.length', 1 do
      PatientMailer.assessment_email(@patient).deliver_now
      @patient.reload
      assert_not_nil @patient.last_assessment_reminder_sent
      assert_equal 'Report Reminder', @patient.histories.first.history_type
      assert_includes @patient.histories.first.comment, "Sara Alert sent a report reminder to this monitoree via #{@patient.preferred_contact_method}."
    end
  end

  test 'assessment email patient with dependents' do
    @patient.update(preferred_contact_method: 'E-mailed Web Link')

    dependent = create(:patient_with_submission_token)
    dependent.update(responder_id: @patient.id)

    email = PatientMailer.enrollment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_includes email_body, dependent.submission_token

    dependent.update(monitoring: false)
    email = PatientMailer.enrollment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_not_includes email_body, dependent.submission_token
  end

  test 'send_assessment does not touch updated_at for E-mailed Web Link when sending an assessment' do
    ActionMailer::Base.deliveries.clear
    patient = create(:patient,
                     submission_token: SecureRandom.urlsafe_base64[0, 10],
                     last_date_of_exposure: Date.yesterday,
                     preferred_contact_method: 'E-mailed Web Link',
                     email: 'testpatient@example.com')
    patient.update(updated_at: 300.days.ago)
    assert_nil patient.last_assessment_reminder_sent
    # If a job is created, then ensure it executes now
    patient.send_assessment&.perform_now
    patient.reload
    assert_not_nil patient.last_assessment_reminder_sent
    assert patient.updated_at < 290.days.ago
  end

  test 'send_assessment does not touch updated_at for E-mailed Web Link when failing to send an assessment' do
    ActionMailer::Base.deliveries.clear
    patient = create(:patient_with_submission_token,
                     last_date_of_exposure: Date.yesterday,
                     preferred_contact_method: 'E-mailed Web Link')
    patient.update(updated_at: 300.days.ago)
    assert_nil patient.last_assessment_reminder_sent
    # If a job is created, then ensure it executes now
    patient.send_assessment&.perform_now
    patient.reload
    assert_nil patient.last_assessment_reminder_sent
    assert patient.updated_at < 290.days.ago
  end

  test 'assessment_email creates an report_email_error history when it fails' do
    ActionMailer::Base.deliveries.clear
    patient = create(:patient,
                     submission_token: SecureRandom.urlsafe_base64[0, 10],
                     preferred_contact_method: 'E-mailed Web Link',
                     email: 'testpatient@example.com')
    original_updated_at = patient.updated_at
    allow_any_instance_of(Patient).to(receive(:select_language).and_raise('Testing assessment_email'))
    assert_difference 'patient.histories.length', 1 do
      PatientMailer.assessment_email(patient).deliver_now
      patient.reload
      assert_equal('Report Email Error', patient.histories.first.history_type)
      assert_equal(patient.updated_at, original_updated_at)
      assert_equal(ActionMailer::Base.deliveries.length, 0)
    end
  end

  test 'assessment_email logs to sentry when it fails' do
    ActionMailer::Base.deliveries.clear
    patient = create(:patient_with_submission_token,
                     preferred_contact_method: 'E-mailed Web Link',
                     email: 'testpatient@example.com')
    allow_any_instance_of(Patient).to(receive(:select_language).and_raise('Testing assessment_email'))
    allow(Raven).to receive(:capture_exception)
    PatientMailer.assessment_email(patient).deliver_now
    expect(Raven).to have_received(:capture_exception)
    assert_equal(ActionMailer::Base.deliveries.length, 0)
  end
end
