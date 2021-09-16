# frozen_string_literal: true

require 'test_case'

class PatientTexterJobTest < ActiveSupport::TestCase
  def setup
    @patient = create(:patient_with_submission_token,
                      primary_language: 'eng',
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

  %w[enrollment assessment_weblink assessment_text].each do |mthd|
    test "#{mthd} no phone provided" do
      @patient.update(primary_telephone: nil)
      assert_nil(PatientTexterJob.perform_now(mthd, @patient))
    end
  end

  %w[enrollment assessment_text assessment_weblink].each do |mthd|
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
        PatientTexterJob.perform_now(mthd, @patient)
        @patient.reload
        assert_equal 'Unsuccessful Report Reminder', @patient.histories.first.history_type
        comment = "Sara Alert attempted to send an SMS to this monitoree at #{@patient.primary_telephone}, but the message could not be delivered."
        assert_includes @patient.histories.first.comment, comment
      end
    end
  end

  %w[assessment_weblink].each do |mthd|
    test "#{mthd} success histories" do
      allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create) do
        true
      end)

      assert_difference '@patient.histories.length', 1 do
        @patient.update(preferred_contact_method: 'SMS Texted Weblink')
        PatientTexterJob.perform_now(mthd, @patient)
        assert_not_nil @patient.last_assessment_reminder_sent
        @patient.reload
        assert_equal 'Report Reminder', @patient.histories.first.history_type
        assert_equal "Sara Alert sent a report reminder to this monitoree via #{@patient.preferred_contact_method}.", @patient.histories.first.comment
      end
    end
  end

  %w[assessment_weblink].each do |mthd|
    test "#{mthd} no phone provided histories" do
      @patient.update(primary_telephone: nil, preferred_contact_method: 'Unknown')
      assert_difference '@patient.histories.length', 1 do
        PatientTexterJob.perform_now(mthd, @patient)
        @patient.reload
        assert_equal 'Unsuccessful Report Reminder', @patient.histories.first.history_type
        assert_includes @patient.histories.first.comment, 'Sara Alert could not send a report reminder to this monitoree via'
        assert_includes @patient.histories.first.comment, @patient.preferred_contact_method
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
    PatientTexterJob.perform_now('assessment_weblink', @patient)
    # 1 Assessment sms weblink will be posted, that post will contain the messages to be sent for the monitoree and their dependent
    assert_equal(create_count, 1)

    # Assert that both the patient and dependent got history items added
    assert_equal patient_history_count + 1, @patient.histories.count
    assert_equal dependent_history_count + 1, dependent.histories.count
  end

  test 'assessment_sms twilio rest error' do
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
      PatientTexterJob.perform_now('assessment_text', @patient)
      @patient.reload
      assert_equal 'Unsuccessful Report Reminder', @patient.histories.first.history_type
      assert_includes @patient.histories.first.comment, @patient.primary_telephone
    end
  end

  test 'assessment_sms success histories' do
    allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create).and_return(true))
    assert_difference '@patient.histories.length', 1 do
      PatientTexterJob.perform_now('assessment_text', @patient)
      @patient.reload
      assert_equal 'Report Reminder', @patient.histories.first.history_type
      assert_includes @patient.histories.first.comment, "Sara Alert sent a report reminder to this monitoree via #{@patient.preferred_contact_method}."
      assert_not_nil @patient.last_assessment_reminder_sent
    end
  end

  [
    { preferred_contact_method: 'SMS Texted Weblink' },
    { preferred_contact_method: 'SMS Text-message' },
    { preferred_contact_method: 'SMS Texted Weblink', primary_telephone: '+12223334444' },
    { preferred_contact_method: 'SMS Text-message', primary_telephone: '+12223334444' }
  ].each do |attributes|
    test "send_assessment does not touch updated_at for #{attributes} when failing to send an assessment" do
      BlockedNumber.create(phone_number: '+12223334444')
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

  Languages.all_languages.filter { |_k, v| v[:supported].present? }.each_key do |language|
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
      PatientTexterJob.perform_later('assessment_text', @patient)

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
      PatientTexterJob.perform_now('assessment_text', @patient)
      # Assert that both the patient and dependent got history items added
      assert_equal patient_history_count + 1, @patient.histories.count
      assert_equal dependent_history_count + 1, dependent.histories.count
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

      PatientTexterJob.perform_now('enrollment', @patient)
    end

    test "assessment sms weblink message contents using messaging service in #{language}" do
      @patient.update(preferred_contact_method: 'SMS Texted Weblink', primary_language: language.to_s)
      web_lang = Languages.supported_language?(language.to_s, :email) ? language.to_s : 'eng'
      url = Rails.application.routes.url_helpers.new_patient_assessment_jurisdiction_lang_initials_url(@patient.submission_token,
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

      PatientTexterJob.perform_now('assessment_weblink', @patient)
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

      PatientTexterJob.perform_now('enrollment', @patient)
    end

    test "assessment sms weblink message contents not using messaging service in #{language}" do
      ENV['TWILLIO_MESSAGING_SERVICE_SID'] = nil
      @patient.update(preferred_contact_method: 'SMS Texted Weblink', primary_language: language.to_s)
      web_lang = Languages.supported_language?(language.to_s, :email) ? language.to_s : 'eng'

      url = Rails.application.routes.url_helpers.new_patient_assessment_jurisdiction_lang_initials_url(@patient.submission_token,
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

      PatientTexterJob.perform_now('assessment_weblink', @patient)
    end
  end
end
