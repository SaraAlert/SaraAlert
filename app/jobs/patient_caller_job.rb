# frozen_string_literal: true

# PatientCallerJob: make voice calls to the Patient.
class PatientCallerJob < ApplicationJob
  include Twilio

  queue_as :mailers

  def perform(type_str, patient)
    case type_str
    when 'assessment'
      PatientCallerJob.assessment(patient)
    else
      raise InvalidMessagingMethodError.new(self.class, type_str)
    end
  end

  def self.assessment(patient)
    twilio_sender = TwilioSender.new('VOICE', patient.primary_telephone)

    lang = patient.select_language(:phone)

    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    patient_names = patient.active_dependents.uniq.map do |dependent|
      I18n.t('assessments.twilio.voice.initials_age', locale: lang, initials: dependent&.initials, age: dependent&.calc_current_age || '0')
    end

    # Prepare text asking about anyone in the group
    plural = patient.active_dependents.uniq.count > 1

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    symptom_names = patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang)

    # Construct message contents
    experiencing_symptoms = I18n.t("assessments.twilio.shared.experiencing_symptoms_#{plural ? 'p' : 's'}", locale: lang, name: patient.initials,
                                                                                                            symptom_names: symptom_names)
    contents = I18n.t('assessments.twilio.voice.daily', locale: lang, names: patient_names.join(', '), experiencing_symptoms: experiencing_symptoms)

    threshold_hash = patient.jurisdiction.current_threshold_condition_hash
    # The medium parameter will either be SMS, VOICE or SINGLE_SMS
    params = { prompt: contents, patient_submission_token: patient.submission_token,
               threshold_hash: threshold_hash, medium: 'VOICE', language: lang.to_s.split('-').first.upcase,
               intro: I18n.t('assessments.twilio.voice.intro', locale: lang),
               try_again: I18n.t('assessments.twilio.voice.try_again', locale: lang),
               max_retries_message: I18n.t('assessments.twilio.shared.max_retries_message', locale: lang),
               thanks: I18n.t('assessments.twilio.voice.thanks', locale: lang) }
    # Update last send attempt timestamp before Twilio call
    patient.last_assessment_reminder_sent = DateTime.now
    patient.save(touch: false)
    if twilio_sender.create_execution(params)
      patient.active_dependents_and_self.each(&:add_report_reminder_success_history)
    else
      TwilioErrorCodes.handle_twilio_error_codes(patient, twilio_sender.error_code)
    end
  end
end
