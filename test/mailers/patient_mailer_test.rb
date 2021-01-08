# frozen_string_literal: true

require 'test_case'

class PatientMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::SanitizeHelper

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  def setup
    patient_email = Faker::Internet.email + rand(100).to_s
    patient_submission_token = SecureRandom.urlsafe_base64[0, 10]
    @patient = create(:patient)
    @patient.update(email: patient_email,
                    primary_language: 'en',
                    submission_token: patient_submission_token,
                    primary_telephone: '+15555550111',
                    preferred_contact_method: 'Telephone call')
    ENV['TWILLIO_SENDING_NUMBER'] = 'test'
    ENV['TWILLIO_API_ACCOUNT'] = 'test'
    ENV['TWILLIO_API_KEY'] = 'test'
    ENV['TWILLIO_STUDIO_FLOW'] = 'test'
    ENV['TWILLIO_MESSAGING_SERVICE_SID'] = 'test_messaging_sid'
  end

  def teardown
    ENV['TWILLIO_SENDING_NUMBER'] = nil
    ENV['TWILLIO_API_ACCOUNT'] = nil
    ENV['TWILLIO_API_KEY'] = nil
    ENV['TWILLIO_STUDIO_FLOW'] = nil
    ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil
  end

  test 'enrollment email contents' do
    email = PatientMailer.enrollment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal [@patient.email], email.to
    assert_equal [PatientMailer.default[:from]], email.from
    assert_equal I18n.t('assessments.email.enrollment.subject', locale: @patient.primary_language), email.subject
    assert_includes email_body, I18n.t('assessments.email.enrollment.header', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.enrollment.dear', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.enrollment.info1', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.enrollment.info2', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.enrollment.report', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.enrollment.footer', locale: @patient.primary_language)
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
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_includes email_body, dependent.submission_token

    dependent.update(monitoring: false)
    email = PatientMailer.enrollment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
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

  %i[enrollment_sms_text_based enrollment_sms_weblink].each do |mthd|
    test "#{mthd} no phone provided" do
      @patient.update(primary_telephone: nil)
      email = PatientMailer.send(mthd, @patient)
      assert_nil email.deliver_now
    end
  end

  %i[enrollment_sms_text_based enrollment_sms_weblink assessment_sms_weblink].each do |mthd|
    test "#{mthd} twilio rest error" do
      def twilio_error
        response_object = double('response_object',
                                 status_code: 500,
                                 body: {})

        Twilio::REST::RestError.new('error', response_object)
      end

      allow_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create) do
        raise twilio_error
      end)

      assert_difference '@patient.histories.length', 1 do
        PatientMailer.send(mthd, @patient).deliver_now
        @patient.reload
        assert_equal 'Report Reminder', @patient.histories.first.history_type
        comment = "Sara Alert attempted to send an SMS to #{@patient.primary_telephone}, but the message could not be delivered."
        assert_includes @patient.histories.first.comment, comment
      end
    end
  end

  test 'enrollment sms weblink message contents' do
    contents = "#{I18n.t('assessments.sms.prompt.intro1', locale: 'en')} -0 #{I18n.t('assessments.sms.prompt.intro2', locale: 'en')}"

    allow_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create) do
      true
    end)
    expect_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create).with(
                                                                                         to: '+15555550111',
                                                                                         body: contents,
                                                                                         from: 'test_messaging_sid'
                                                                                       ))

    PatientMailer.enrollment_sms_weblink(@patient).deliver_now
  end

  test 'enrollment sms weblink message contents not using messaging service' do
    ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil

    contents = "#{I18n.t('assessments.sms.prompt.intro1', locale: 'en')} -0 #{I18n.t('assessments.sms.prompt.intro2', locale: 'en')}"

    # Assert correct REST call when messaging_service is NOT used falls back to from number
    allow_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create) do
      true
    end)
    expect_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create).with(
                                                                                         to: '+15555550111',
                                                                                         body: contents,
                                                                                         from: 'test'
                                                                                       ))

    PatientMailer.enrollment_sms_weblink(@patient).deliver_now
  end

  test 'enrollment sms text based message contents using messaging service' do
    contents = "#{I18n.t('assessments.sms.prompt.intro1', locale: 'en')} -0 #{I18n.t('assessments.sms.prompt.intro2', locale: 'en')}"

    allow_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create) do
      true
    end)
    expect_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create).with(
                                                                                         to: '+15555550111',
                                                                                         body: contents,
                                                                                         from: 'test_messaging_sid'
                                                                                       ))

    PatientMailer.enrollment_sms_text_based(@patient).deliver_now
  end

  test 'enrollment sms text based message contents not using messaging service' do
    ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil
    contents = "#{I18n.t('assessments.sms.prompt.intro1', locale: 'en')} -0 #{I18n.t('assessments.sms.prompt.intro2', locale: 'en')}"

    allow_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create) do
      true
    end)
    expect_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create).with(
                                                                                         to: '+15555550111',
                                                                                         body: contents,
                                                                                         from: 'test'
                                                                                       ))

    PatientMailer.enrollment_sms_text_based(@patient).deliver_now
  end

  test 'assessment sms weblink message contents using messaging service' do
    url = new_patient_assessment_jurisdiction_lang_initials_url(@patient.submission_token,
                                                                @patient.jurisdiction.unique_identifier,
                                                                'en',
                                                                @patient&.initials_age)
    contents = "#{I18n.t('assessments.sms.weblink.intro', locale: 'en')} -0: #{url}"

    allow_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create) do
      true
    end)
    expect_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create).with(
                                                                                         to: '+15555550111',
                                                                                         body: contents,
                                                                                         from: 'test_messaging_sid'
                                                                                       ))

    PatientMailer.assessment_sms_weblink(@patient).deliver_now
  end

  test 'assessment sms weblink message contents not using messaging service' do
    ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil

    url = new_patient_assessment_jurisdiction_lang_initials_url(@patient.submission_token,
                                                                @patient.jurisdiction.unique_identifier,
                                                                'en',
                                                                @patient&.initials_age)
    contents = "#{I18n.t('assessments.sms.weblink.intro', locale: 'en')} -0: #{url}"

    allow_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create) do
      true
    end)
    expect_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create).with(
                                                                                         to: '+15555550111',
                                                                                         body: contents,
                                                                                         from: 'test'
                                                                                       ))

    PatientMailer.assessment_sms_weblink(@patient).deliver_now
  end

  test 'assessment sms weblink message contents with dependents' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.urlsafe_base64[0, 10])

    # Cannot do the same expectation as previous tests because the expectation that any instance gets called with create is taken up by the first loop of
    # sending messages. So instead we count the amount of times create was called. Cannot do this with typical rspec methods because when you use
    # any_instance_of the expectation for number of calls applies to EVERY instance, not just any single instance. Instead we calculate
    # based on our mock method.
    create_count = 0
    allow_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create) do
      create_count += 1
      true
    end)

    PatientMailer.assessment_sms_weblink(@patient).deliver_now
    assert_equal create_count, 2
  end

  %i[assessment_sms_weblink].each do |mthd|
    test "#{mthd} success histories" do
      allow_any_instance_of(::Twilio::REST::Api::V2010::AccountContext::MessageList).to(receive(:create) do
        true
      end)

      assert_difference '@patient.histories.length', 1 do
        PatientMailer.send(mthd, @patient).deliver_now
        assert_not_nil @patient.last_assessment_reminder_sent
        @patient.reload
        assert_equal 'Report Reminder', @patient.histories.first.history_type
        assert_equal "Sara Alert sent a report reminder to this monitoree via #{@patient.preferred_contact_method}.", @patient.histories.first.comment
      end
    end
  end

  %i[assessment_sms_weblink].each do |mthd|
    test "#{mthd} no phone provided" do
      @patient.update(primary_telephone: nil)
      assert_difference '@patient.histories.length', 1 do
        PatientMailer.send(mthd, @patient).deliver_now
        @patient.reload
        assert_equal 'Report Reminder', @patient.histories.first.history_type
        assert_includes @patient.histories.first.comment, 'Sara Alert could not send a report reminder to this monitoree via'
        assert_includes @patient.histories.first.comment, @patient.preferred_contact_method
      end
    end
  end

  %i[assessment_sms assessment_voice].each do |mthd|
    test "#{mthd} twilio rest error" do
      def twilio_error
        response_object = double('response_object',
                                 status_code: 500,
                                 body: {})

        Twilio::REST::RestError.new('error', response_object)
      end

      allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
        raise twilio_error
      end)
      assert_difference '@patient.histories.length', 1 do
        PatientMailer.send(mthd, @patient).deliver_now
        @patient.reload
        assert_equal 'Report Reminder', @patient.histories.first.history_type
        assert_includes @patient.histories.first.comment, @patient.primary_telephone
      end
    end
  end

  %i[assessment_sms assessment_voice].each do |mthd|
    test "#{mthd} success histories" do
      allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create).and_return(true))
      assert_difference '@patient.histories.length', 1 do
        PatientMailer.send(mthd, @patient).deliver_now
        @patient.reload
        assert_equal 'Report Reminder', @patient.histories.first.history_type
        assert_includes @patient.histories.first.comment, "Sara Alert sent a report reminder to this monitoree via #{@patient.preferred_contact_method}."
        assert_not_nil @patient.last_assessment_reminder_sent
      end
    end
  end

  test 'assessment sms message content using messaging service' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.urlsafe_base64[0, 10])

    params = {
      language: 'EN',
      try_again: I18n.t('assessments.sms.prompt.try-again', locale: 'en'),
      thanks: I18n.t('assessments.sms.prompt.thanks', locale: 'en'),
      medium: 'SMS',
      max_retries_message: I18n.t('assessments.sms.prompt.max_retries_message', locale: 'en'),
      patient_submission_token: @patient.submission_token,
      # Don't have any symptoms set up for this jurisdiction.
      threshold_hash: @patient.jurisdiction.jurisdiction_path_threshold_hash,
      # rubocop:disable Layout/LineLength
      prompt: "#{I18n.t('assessments.sms.prompt.daily1', locale: 'en')}-0, -0.#{I18n.t('assessments.sms.prompt.daily2-p', locale: 'en')}#{I18n.t('assessments.sms.prompt.daily3', locale: 'en')}#{@patient.jurisdiction.hierarchical_condition_bool_symptoms_string('en')}.#{I18n.t('assessments.sms.prompt.daily4', locale: 'en')}"
      # rubocop:enable Layout/LineLength
    }

    allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
      true
    end)
    expect_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create)).with({
                                                                                                               to: '+15555550111',
                                                                                                               parameters: params,
                                                                                                               from: 'test_messaging_sid'
                                                                                                             })
    PatientMailer.assessment_sms(@patient).deliver_now
  end

  test 'assessment sms message content not using messaging service' do
    ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.hex(20))

    params = {
      language: 'EN',
      try_again: I18n.t('assessments.sms.prompt.try-again', locale: 'en'),
      thanks: I18n.t('assessments.sms.prompt.thanks', locale: 'en'),
      medium: 'SMS',
      max_retries_message: I18n.t('assessments.sms.prompt.max_retries_message', locale: 'en'),
      patient_submission_token: @patient.submission_token,
      # Don't have any symptoms set up for this jurisdiction.
      threshold_hash: @patient.jurisdiction.jurisdiction_path_threshold_hash,
      # rubocop:disable Layout/LineLength
      prompt: "#{I18n.t('assessments.sms.prompt.daily1', locale: 'en')}-0, -0.#{I18n.t('assessments.sms.prompt.daily2-p', locale: 'en')}#{I18n.t('assessments.sms.prompt.daily3', locale: 'en')}#{@patient.jurisdiction.hierarchical_condition_bool_symptoms_string('en')}.#{I18n.t('assessments.sms.prompt.daily4', locale: 'en')}"
      # rubocop:enable Layout/LineLength
    }

    allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
      true
    end)
    expect_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create)).with({
                                                                                                               to: '+15555550111',
                                                                                                               parameters: params,
                                                                                                               from: 'test'
                                                                                                             })
    PatientMailer.assessment_sms(@patient).deliver_now
  end

  test 'assessment voice message content should not use messaging service' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.urlsafe_base64[0, 10])
    @patient.update(primary_language: 'so')

    params = {
      language: 'EN',
      intro: I18n.t('assessments.phone.intro', locale: 'en'),
      try_again: I18n.t('assessments.phone.try-again', locale: 'en'),
      thanks: I18n.t('assessments.phone.thanks', locale: 'en'),
      max_retries_message: I18n.t('assessments.phone.max_retries_message', locale: 'en'),
      medium: 'VOICE',
      patient_submission_token: @patient.submission_token,
      # Don't have any symptoms set up for this jurisdiction.
      threshold_hash: @patient.jurisdiction.jurisdiction_path_threshold_hash,
      # rubocop:disable Layout/LineLength
      prompt: "#{I18n.t('assessments.phone.daily1', locale: 'en')}, , #{I18n.t('assessments.phone.age', locale: 'en')} 0,, , , #{I18n.t('assessments.phone.age', locale: 'en')} 0,#{I18n.t('assessments.phone.daily2-p', locale: 'en')}#{I18n.t('assessments.phone.daily3', locale: 'en')}#{@patient.jurisdiction.hierarchical_condition_bool_symptoms_string('en')}?#{I18n.t('assessments.phone.daily4', locale: 'en')}"
      # rubocop:enable Layout/LineLength
    }

    allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
      true
    end)
    expect_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create)).with({
                                                                                                               from: 'test',
                                                                                                               to: '+15555550111',
                                                                                                               parameters: params
                                                                                                             })
    PatientMailer.assessment_voice(@patient).deliver_now
  end

  test 'assessment email contents' do
    email = PatientMailer.assessment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal [@patient.email], email.to
    assert_equal [PatientMailer.default[:from]], email.from
    assert_equal I18n.t('assessments.email.reminder.subject', locale: @patient.primary_language), email.subject
    assert_includes email_body, I18n.t('assessments.email.reminder.header', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.reminder.dear', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.reminder.thank-you', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.reminder.report', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.reminder.footer', locale: @patient.primary_language)
  end

  test 'assessment email with dependents' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.urlsafe_base64[0, 10])
    email = PatientMailer.assessment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_includes email_body, dependent.submission_token

    @patient.update(last_assessment_reminder_sent: nil)
    dependent.update(monitoring: false)
    email = PatientMailer.assessment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_not_includes email_body, dependent.submission_token
  end

  test 'assessment email history and reminder' do
    assert_difference '@patient.histories.length', 1 do
      PatientMailer.assessment_email(@patient).deliver_now
      @patient.reload
      assert_not_nil @patient.last_assessment_reminder_sent
      assert_equal 'Report Reminder', @patient.histories.first.history_type
      assert_includes @patient.histories.first.comment, "Sara Alert sent a report reminder to this monitoree via #{@patient.preferred_contact_method}."
    end
  end

  test 'assessment email patient with dependents' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.urlsafe_base64[0, 10])
    email = PatientMailer.enrollment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_includes email_body, dependent.submission_token

    dependent.update(monitoring: false)
    email = PatientMailer.enrollment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_not_includes email_body, dependent.submission_token
  end

  test 'closed email contents' do
    email = PatientMailer.closed_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_equal [@patient.email], email.to
    assert_equal [PatientMailer.default[:from]], email.from
    assert_equal I18n.t('assessments.email.closed.subject', locale: @patient.primary_language), email.subject
    assert_includes email_body, I18n.t('assessments.email.closed.header', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.closed.dear', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.closed.thank-you', locale: @patient.primary_language)
    assert_includes email_body, I18n.t('assessments.email.closed.footer', locale: @patient.primary_language)
  end
end
