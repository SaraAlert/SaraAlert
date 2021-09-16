# frozen_string_literal: true

require 'test_case'

class PatientCallerJobTest < ActiveSupport::TestCase
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

  test 'assessment twilio rest error' do
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
      PatientCallerJob.perform_now('assessment', @patient)
      @patient.reload
      assert_equal 'Unsuccessful Report Reminder', @patient.histories.first.history_type
      assert_includes @patient.histories.first.comment, @patient.primary_telephone
    end
  end

  test 'assessment success histories' do
    allow_any_instance_of(::Twilio::REST::Studio::V1::FlowContext::ExecutionList).to(receive(:create).and_return(true))
    assert_difference '@patient.histories.length', 1 do
      PatientCallerJob.perform_now('assessment', @patient)
      @patient.reload
      assert_equal 'Report Reminder', @patient.histories.first.history_type
      assert_includes @patient.histories.first.comment, "Sara Alert sent a report reminder to this monitoree via #{@patient.preferred_contact_method}."
      assert_not_nil @patient.last_assessment_reminder_sent
    end
  end

  Languages.all_languages.each_key.select { |l| Languages.supported_language?(l, :phone) }.each do |language|
    test "assessment message content should not use messaging service in #{language}" do
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
      PatientCallerJob.perform_now('assessment', @patient)

      # Assert that both the patient and dependent got history items added
      assert_equal patient_history_count + 1, @patient.histories.count
      assert_equal dependent_history_count + 1, dependent.histories.count
    end
  end
end
