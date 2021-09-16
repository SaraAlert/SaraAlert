# frozen_string_literal: true

# PatientSmsSender: SMS Sender for Monitorees
# Contains the methods that any SMS provider (such as the ones in lib/twilio
# must implement
class PatientTexterJob < ApplicationJob
  include Twilio

  queue_as :mailers

  rescue_from ActiveJob::DeserializationError do |exception|
    Sidekiq.logger.error(exception)
  end

  def perform(type_str, patient)
    # This function has the side-effect of creating history items for the patient
    return if PatientTexterJob.blocked_or_missing_telephone?(type_str, patient)

    case type_str
    when 'enrollment'
      PatientTexterJob.enrollment(patient)
    when 'assessment_text'
      PatientTexterJob.assessment_text(patient)
    when 'assessment_weblink'
      PatientTexterJob.assessment_weblink(patient)
    when 'close'
      PatientTexterJob.close(patient)
    else
      raise InvalidMessagingMethodError.new(self.class, type_str)
    end
  end

  def self.enrollment(patient)
    twilio_sender = TwilioSender.new('SINGLE_SMS', patient.primary_telephone)
    params = {
      messages_array: [{
        prompt: I18n.t('assessments.twilio.sms.prompt.intro',
                       locale: patient.select_language(:sms),
                       name: patient&.initials_age('-')),
        patient_submission_token: patient.submission_token,
        threshold_hash: patient.jurisdiction.current_threshold_condition_hash
      }],
      medium: 'SINGLE_SMS'
    }

    if twilio_sender.create_execution(params)
      History.welcome_message_sent(patient: patient)
    else
      TwilioErrorCodes.handle_twilio_error_codes(patient, twilio_sender.error_code)
    end

    # Always update the last contact time so the system does not try and send sms again.
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end

  # Right now the wording of this message is the same as for enrollment
  def self.assessment_weblink(patient)
    # Cover potential race condition where multiple messages are sent for the same monitoree.
    return unless patient.last_assessment_reminder_sent_eligible?

    messages_array = []

    sms_lang = patient.select_language(:sms)
    web_lang = patient.select_language(:email)

    patient.active_dependents.uniq.each do |dependent|
      url = Rails.application.routes.url_helpers.new_patient_assessment_jurisdiction_lang_initials_url(dependent.submission_token,
                                                                                                       dependent.jurisdiction.unique_identifier,
                                                                                                       web_lang&.to_s,
                                                                                                       dependent&.initials_age)
      contents = I18n.t('assessments.twilio.sms.weblink.intro', locale: sms_lang, initials_age: dependent&.initials_age('-'), url: url)
      # Update last send attempt timestamp before Twilio call
      patient.last_assessment_reminder_sent = DateTime.now
      patient.save(touch: false)
      threshold_hash = dependent.jurisdiction[:current_threshold_condition_hash]
      message = { prompt: contents, patient_submission_token: dependent.submission_token,
                  threshold_hash: threshold_hash }
      messages_array << message
    end
    params = { messages_array: messages_array, medium: 'SINGLE_SMS' }
    twilio_sender = TwilioSender.new('SINGLE_SMS', patient.primary_telephone)

    if twilio_sender.create_execution(params)
      patient.active_dependents_and_self.each(&:add_report_reminder_success_history)
    else
      TwilioErrorCodes.handle_twilio_error_codes(patient, twilio_sender.error_code)
    end
  end

  def self.assessment_text(patient)
    # Cover potential race condition where multiple messages are sent for the same monitoree.
    return unless patient.last_assessment_reminder_sent_eligible?

    twilio_sender = TwilioSender.new('SMS', patient.primary_telephone)

    lang = patient.select_language(:sms)

    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    patient_names = patient.active_dependents.uniq.map do |dependent|
      I18n.t('assessments.twilio.sms.prompt.name', locale: lang, name: dependent&.initials_age('-'))
    end.join(', ')

    # Prepare text asking about anyone in the group
    plural = patient.active_dependents.uniq.count > 1

    # Construct message contents
    # The call to hierarchical_condition_bool_symptoms_string assumes that all of the dependents will be in the same jurisdiction
    # and therefore have the same symptom questions if the dependets are in a different jurisdiction they may end up with too many
    # or too few symptoms in their response
    experiencing_symptoms = I18n.t("assessments.twilio.shared.experiencing_symptoms_#{plural ? 'p' : 's'}",
                                   locale: lang,
                                   name: patient.initials,
                                   symptom_names: patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang))

    params = {
      prompt: I18n.t('assessments.twilio.sms.prompt.daily',
                     locale: lang,
                     names: patient_names,
                     experiencing_symptoms: experiencing_symptoms),
      patient_submission_token: patient.submission_token,
      threshold_hash: patient.jurisdiction.current_threshold_condition_hash,
      medium: 'SMS',
      language: lang.to_s.split('-').first.upcase,
      try_again: I18n.t('assessments.twilio.sms.prompt.try_again', locale: lang),
      max_retries_message: I18n.t('assessments.twilio.shared.max_retries_message', locale: lang),
      thanks: I18n.t('assessments.twilio.sms.prompt.thanks', locale: lang)
    }
    # Update last send attempt timestamp before Twilio sms assessment
    patient.last_assessment_reminder_sent = DateTime.now
    patient.save(touch: false)
    if twilio_sender.create_execution(params)
      patient.active_dependents_and_self.each(&:add_report_reminder_success_history)
    else
      TwilioErrorCodes.handle_twilio_error_codes(patient, twilio_sender.error_code)
    end
  end

  def self.close(patient)
    params = {
      messages_array: [{
        prompt: I18n.t('assessments.twilio.sms.closed.thank_you',
                       initials_age: patient&.initials_age('-'),
                       completed_date: patient.closed_at&.strftime('%m-%d-%Y'),
                       locale: patient.select_language(:sms)),
        patient_submission_token: patient.submission_token,
        threshold_hash: patient.jurisdiction[:current_threshold_condition_hash]
      }],
      medium: 'SINGLE_SMS'
    }

    twilio_sender = TwilioSender.new('SINGLE_SMS', patient.primary_telephone)
    twilio_sender.create_execution(params)
    History.monitoring_complete_message_sent(patient: patient)
  end

  def self.blocked_or_missing_telephone?(type_str, patient)
    if patient&.primary_telephone.blank?
      if type_str == 'close'
        History.send_close_contact_method_blank(patient: patient, type: 'primary phone number')
      else
        patient.add_report_reminder_fail_history_blank_field('primary_phone_number')
      end
    elsif patient&.blocked_sms
      if type_str == 'close'
        History.send_close_sms_blocked(patient: patient)
      else
        TwilioErrorCodes.handle_twilio_error_codes(patient, TwilioErrorCodes::CODES[:blocked_number][:code])
      end
    else
      return false
    end

    true
  end
end
