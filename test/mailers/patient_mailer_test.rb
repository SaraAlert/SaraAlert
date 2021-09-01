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
    @patient = create(:patient_with_submission_token)
    @patient.update(email: patient_email,
                    primary_language: 'eng',
                    primary_telephone: '+15555550111',
                    preferred_contact_method: 'Telephone call')
    ENV['TWILLIO_SENDING_NUMBER'] = 'test'
    ENV['TWILLIO_API_ACCOUNT'] = 'test'
    ENV['TWILLIO_API_KEY'] = 'test'
    ENV['TWILLIO_STUDIO_FLOW'] = 'test'
    ENV['TWILLIO_MESSAGING_SERVICE_SID'] = 'test_messaging_sid'
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
  end

  def teardown
    ENV['TWILLIO_SENDING_NUMBER'] = nil
    ENV['TWILLIO_API_ACCOUNT'] = nil
    ENV['TWILLIO_API_KEY'] = nil
    ENV['TWILLIO_STUDIO_FLOW'] = nil
    ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil
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
        @patient.update(preferred_contact_method: 'SMS Weblink')
        PatientMailer.send(mthd, @patient).deliver_now
        @patient.reload
        assert_equal 'Unsuccessful Report Reminder', @patient.histories.first.history_type
        comment = "Sara Alert attempted to send an SMS to this monitoree at #{@patient.primary_telephone}, but the message could not be delivered."
        assert_includes @patient.histories.first.comment, comment
      end
    end
  end

  test 'assessment sms weblink message with dependents' do
    @patient.update(preferred_contact_method: 'SMS Texted Weblink')
    dependent = create(:patient_with_submission_token)
    dependent.update(responder_id: @patient.id)

    dependent_history_count = dependent.histories.count
    patient_history_count = @patient.histories.count
    # Cannot do the same expectation as previous tests because the expectation that any instance gets called with create is taken up by the first loop of
    # sending messages. So instead we count the amount of times create was called. Cannot do this with typical rspec methods because when you use
    # any_instance_of the expectation for number of calls applies to EVERY instance, not just any single instance. Instead we calculate
    # based on our mock method.
    create_count = 0
    allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
      create_count += 1
      true
    end)
    PatientMailer.assessment_sms_weblink(@patient).deliver_now
    # 1 Assessment sms weblink will be posted, that post will contain the messages to be sent for the monitoree and their dependent
    assert_equal create_count, 1

    # Assert that both the patient and dependent got history items added
    assert_equal patient_history_count + 1, @patient.histories.count
    assert_equal dependent_history_count + 1, dependent.histories.count
  end

  %i[assessment_sms_weblink].each do |mthd|
    test "#{mthd} success histories" do
      allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
        true
      end)

      assert_difference '@patient.histories.length', 1 do
        @patient.update(preferred_contact_method: 'SMS Texted Weblink')
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
      @patient.update(primary_telephone: nil, preferred_contact_method: 'Unknown')
      assert_difference '@patient.histories.length', 1 do
        PatientMailer.send(mthd, @patient).deliver_now
        @patient.reload
        assert_equal 'Unsuccessful Report Reminder', @patient.histories.first.history_type
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
        assert_equal 'Unsuccessful Report Reminder', @patient.histories.first.history_type
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

    test "enrollment sms weblink message contents not using messaging service in #{language}" do
      ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil
      @patient.update(primary_language: language.to_s)
      lang = Languages.supported_language?(language.to_s, :sms) ? language.to_s : 'eng'
      contents = I18n.t('assessments.twilio.sms.prompt.intro', locale: lang, name: '-0')

      # Assert correct REST call when messaging_service is NOT used falls back to from number
      allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
        true
      end)
      expect_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create).with(
                                                                                          from: 'test',
                                                                                          parameters:
                                                                                            { medium: 'SINGLE_SMS',
                                                                                              messages_array: [{
                                                                                                patient_submission_token: @patient.submission_token,
                                                                                                prompt: contents,
                                                                                                threshold_hash:
                                                                                                @patient.jurisdiction[:current_threshold_condition_hash]
                                                                                              }] },
                                                                                          to: '+15555550111'
                                                                                        ))

      PatientMailer.enrollment_sms_weblink(@patient).deliver_now
    end

    test "enrollment sms text based message contents using messaging service in #{language}" do
      lang = Languages.supported_language?(language.to_s, :sms) ? language.to_s : 'eng'
      contents = I18n.t('assessments.twilio.sms.prompt.intro', locale: lang, name: '-0')
      @patient.update(primary_language: language.to_s)

      allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
        true
      end)
      expect_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create).with(
                                                                                          from: 'test_messaging_sid',
                                                                                          parameters: {
                                                                                            medium: 'SINGLE_SMS',
                                                                                            messages_array: [
                                                                                              {
                                                                                                patient_submission_token: @patient.submission_token,
                                                                                                prompt: contents,
                                                                                                threshold_hash:
                                                                                                @patient.jurisdiction[:current_threshold_condition_hash]
                                                                                              }
                                                                                            ]
                                                                                          },
                                                                                          to: '+15555550111'
                                                                                        ))

      PatientMailer.enrollment_sms_text_based(@patient).deliver_now
    end

    test "enrollment sms text based message contents not using messaging service in #{language}" do
      ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil
      @patient.update(primary_language: language.to_s)
      lang = Languages.supported_language?(language.to_s, :sms) ? language.to_s : 'eng'
      contents = I18n.t('assessments.twilio.sms.prompt.intro', locale: lang, name: '-0')

      allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
        true
      end)
      expect_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create).with(
                                                                                          from: 'test',
                                                                                          parameters:
                                                                                            { medium: 'SINGLE_SMS',
                                                                                              messages_array: [{
                                                                                                patient_submission_token: @patient.submission_token,
                                                                                                prompt: contents,
                                                                                                threshold_hash:
                                                                                              @patient.jurisdiction[:current_threshold_condition_hash]
                                                                                              }] },
                                                                                          to: '+15555550111'
                                                                                        ))

      PatientMailer.enrollment_sms_text_based(@patient).deliver_now
    end

    test "assessment sms weblink message contents using messaging service in #{language}" do
      @patient.update(preferred_contact_method: 'SMS Texted Weblink', primary_language: language.to_s)
      web_lang = Languages.supported_language?(language.to_s, :email) ? language.to_s : 'eng'
      url = new_patient_assessment_jurisdiction_lang_initials_url(@patient.submission_token,
                                                                  @patient.jurisdiction.unique_identifier,
                                                                  web_lang,
                                                                  @patient&.initials_age)
      sms_lang = Languages.supported_language?(language.to_s, :sms) ? language.to_s : 'eng'
      contents = I18n.t('assessments.twilio.sms.weblink.intro', locale: sms_lang, initials_age: '-0', url: url)

      allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
        true
      end)
      expect_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create).with(
                                                                                          from: 'test_messaging_sid',
                                                                                          parameters:
                                                                                            { medium: 'SINGLE_SMS',
                                                                                              messages_array: [{
                                                                                                patient_submission_token: @patient.submission_token,
                                                                                                prompt: contents,
                                                                                                threshold_hash:
                                                                                              @patient.jurisdiction[:current_threshold_condition_hash]
                                                                                              }] },
                                                                                          to: '+15555550111'
                                                                                        ))

      PatientMailer.assessment_sms_weblink(@patient).deliver_now
    end

    test "assessment sms weblink message contents not using messaging service in #{language}" do
      ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil
      @patient.update(preferred_contact_method: 'SMS Texted Weblink', primary_language: language.to_s)
      web_lang = Languages.supported_language?(language.to_s, :email) ? language.to_s : 'eng'

      url = new_patient_assessment_jurisdiction_lang_initials_url(@patient.submission_token,
                                                                  @patient.jurisdiction.unique_identifier,
                                                                  web_lang,
                                                                  @patient&.initials_age)
      sms_lang = Languages.supported_language?(language.to_s, :sms) ? language.to_s : 'eng'
      contents = I18n.t('assessments.twilio.sms.weblink.intro', locale: sms_lang, initials_age: '-0', url: url)

      allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
        true
      end)
      expect_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create).with(
                                                                                          from: 'test',
                                                                                          parameters:
                                                                                            { medium: 'SINGLE_SMS',
                                                                                              messages_array: [{
                                                                                                patient_submission_token: @patient.submission_token,
                                                                                                prompt: contents,
                                                                                                threshold_hash:
                                                                                              @patient.jurisdiction[:current_threshold_condition_hash]
                                                                                              }] },
                                                                                          to: '+15555550111'
                                                                                        ))

      PatientMailer.assessment_sms_weblink(@patient).deliver_now
    end

    if Languages.supported_language?(language, :phone)
      test "assessment voice message content should not use messaging service in #{language}" do
        dependent = create(:patient_with_submission_token)
        dependent.update(responder_id: @patient.id)
        @patient.update(primary_language: language.to_s, preferred_contact_method: 'Telephone Call')

        dependent_history_count = dependent.histories.count
        patient_history_count = @patient.histories.count

        patient_names = @patient.active_dependents.uniq.map do |dep|
          I18n.t('assessments.twilio.voice.initials_age', locale: language.to_s, initials: dep&.initials, age: dep&.calc_current_age || '0')
        end

        symptom_names = @patient.jurisdiction.hierarchical_condition_bool_symptoms_string(language.to_s)
        experiencing_symptoms = I18n.t('assessments.twilio.shared.experiencing_symptoms_p', locale: language.to_s, name: @patient.initials,
                                                                                            symptom_names: symptom_names)
        contents = I18n.t('assessments.twilio.voice.daily', locale: language.to_s, names: patient_names.join(', '),
                                                            experiencing_symptoms: experiencing_symptoms)

        params = {
          language: language.to_s.split('-').first.upcase,
          intro: I18n.t('assessments.twilio.voice.intro', locale: language.to_s),
          try_again: I18n.t('assessments.twilio.voice.try_again', locale: language.to_s),
          thanks: I18n.t('assessments.twilio.voice.thanks', locale: language.to_s),
          max_retries_message: I18n.t('assessments.twilio.shared.max_retries_message', locale: language.to_s),
          medium: 'VOICE',
          patient_submission_token: @patient.submission_token,
          # Don't have any symptoms set up for this jurisdiction.
          threshold_hash: @patient.jurisdiction[:current_threshold_condition_hash],
          prompt: contents
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

        # Assert that both the patient and dependent got history items added
        assert_equal patient_history_count + 1, @patient.histories.count
        assert_equal dependent_history_count + 1, dependent.histories.count
      end
    end

    test "assessment sms message content not using messaging service #{language}" do
      ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil
      @patient.update(preferred_contact_method: 'SMS Text-Message', primary_language: language.to_s)
      dependent = create(:patient)
      dependent.update(responder_id: @patient.id, submission_token: SecureRandom.hex(20))

      dependent_history_count = dependent.histories.count
      patient_history_count = @patient.histories.count

      lang = Languages.supported_language?(language.to_s, :sms) ? language.to_s : 'eng'
      patient_names = @patient.active_dependents.uniq.map do |dep|
        I18n.t('assessments.twilio.sms.prompt.name', locale: lang, name: dep&.initials_age('-'))
      end

      symptom_names = @patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang)
      experiencing_symptoms = I18n.t('assessments.twilio.shared.experiencing_symptoms_p', locale: lang, name: @patient.initials,
                                                                                          symptom_names: symptom_names)
      contents = I18n.t('assessments.twilio.sms.prompt.daily', locale: lang, names: patient_names.join(', '),
                                                               experiencing_symptoms: experiencing_symptoms)

      params = {
        language: lang.split('-').first.upcase,
        try_again: I18n.t('assessments.twilio.sms.prompt.try_again', locale: lang),
        thanks: I18n.t('assessments.twilio.sms.prompt.thanks', locale: lang),
        medium: 'SMS',
        max_retries_message: I18n.t('assessments.twilio.shared.max_retries_message', locale: lang),
        patient_submission_token: @patient.submission_token,
        # Don't have any symptoms set up for this jurisdiction.
        threshold_hash: @patient.jurisdiction[:current_threshold_condition_hash],
        prompt: contents
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

      # Assert that both the patient and dependent got history items added
      assert_equal patient_history_count + 1, @patient.histories.count
      assert_equal dependent_history_count + 1, dependent.histories.count
    end

    test "assessment sms message content using messaging service #{language}" do
      @patient.update(preferred_contact_method: 'SMS Text-Message', primary_language: language.to_s)

      dependent = create(:patient_with_submission_token)
      dependent.update(responder_id: @patient.id)

      dependent_history_count = dependent.histories.count
      patient_history_count = @patient.histories.count

      lang = Languages.supported_language?(language.to_s, :sms) ? language.to_s : 'eng'
      patient_names = @patient.active_dependents.uniq.map do |dep|
        I18n.t('assessments.twilio.sms.prompt.name', locale: lang, name: dep&.initials_age('-'))
      end

      symptom_names = @patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang)
      experiencing_symptoms = I18n.t('assessments.twilio.shared.experiencing_symptoms_p', locale: lang, name: @patient.initials,
                                                                                          symptom_names: symptom_names)
      contents = I18n.t('assessments.twilio.sms.prompt.daily', locale: lang, names: patient_names.join(', '),
                                                               experiencing_symptoms: experiencing_symptoms)

      params = {
        language: lang.split('-').first.upcase,
        try_again: I18n.t('assessments.twilio.sms.prompt.try_again', locale: lang),
        thanks: I18n.t('assessments.twilio.sms.prompt.thanks', locale: lang),
        medium: 'SMS',
        max_retries_message: I18n.t('assessments.twilio.shared.max_retries_message', locale: lang),
        patient_submission_token: @patient.submission_token,
        # Don't have any symptoms set up for this jurisdiction.
        threshold_hash: @patient.jurisdiction[:current_threshold_condition_hash],
        prompt: contents
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
      # Assert that both the patient and dependent got history items added
      assert_equal patient_history_count + 1, @patient.histories.count
      assert_equal dependent_history_count + 1, dependent.histories.count
    end
  end

  test 'assessment email with dependents' do
    @patient.update(preferred_contact_method: 'E-mailed Web Link')

    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.urlsafe_base64[0, 10])

    dependent_history_count = dependent.histories.count
    patient_history_count = @patient.histories.count

    email = PatientMailer.assessment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_includes email_body, dependent.submission_token

    @patient.update(last_assessment_reminder_sent: nil)
    dependent.update(monitoring: false)
    email = PatientMailer.assessment_email(@patient).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes email_body, @patient.submission_token
    assert_not_includes email_body, dependent.submission_token

    # Assert that the HoH (patient) got a history item for both emails
    assert_equal patient_history_count + 2, @patient.histories.count
    # Assert that the dependent got a history item for only the email pertaining to them
    assert_equal dependent_history_count + 1, dependent.histories.count
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

  [
    { preferred_contact_method: 'E-mailed Web Link', email: 'testpatient@example.com' },
    { preferred_contact_method: 'SMS Texted Weblink', primary_telephone: '+12223334444' },
    { preferred_contact_method: 'Telephone call', primary_telephone: '+12223334444' },
    { preferred_contact_method: 'SMS Text-message', primary_telephone: '+12223334444' }
  ].each do |attributes|
    test "send_assessment does not touch updated_at for #{attributes} when sending an assessment" do
      ActionMailer::Base.deliveries.clear
      patient = create(:patient, { submission_token: SecureRandom.urlsafe_base64[0, 10], last_date_of_exposure: Date.yesterday }.merge(attributes))
      patient.update(updated_at: 300.days.ago)
      assert_nil patient.last_assessment_reminder_sent
      # If a job is created, then ensure it executes now
      patient.send_assessment&.perform_now
      patient.reload
      assert_not_nil patient.last_assessment_reminder_sent
      assert patient.updated_at < 290.days.ago
    end
  end

  [
    { preferred_contact_method: 'E-mailed Web Link' },
    { preferred_contact_method: 'SMS Texted Weblink' },
    { preferred_contact_method: 'Telephone call' },
    { preferred_contact_method: 'SMS Text-message' },
    { preferred_contact_method: 'SMS Texted Weblink', primary_telephone: '+12223334444' },
    { preferred_contact_method: 'SMS Text-message', primary_telephone: '+12223334444' }
  ].each do |attributes|
    test "send_assessment does not touch updated_at for #{attributes} when failing to send an assessment" do
      BlockedNumber.create(phone_number: '+12223334444')
      ActionMailer::Base.deliveries.clear
      patient = create(:patient_with_submission_token, { last_date_of_exposure: Date.yesterday }.merge(attributes))
      patient.update(updated_at: 300.days.ago)
      assert_nil patient.last_assessment_reminder_sent
      # If a job is created, then ensure it executes now
      patient.send_assessment&.perform_now
      patient.reload
      assert_nil patient.last_assessment_reminder_sent
      assert patient.updated_at < 290.days.ago
    end
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
