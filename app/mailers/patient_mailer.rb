# frozen_string_literal: true

# PatientMailer: mailers for monitorees
class PatientMailer < ApplicationMailer
  default from: 'notifications@saraalert.org'

  def enrollment_email(patient)
    # Should not be sending enrollment email if no valid email
    return if patient&.email.blank?

    # Gather patients and jurisdictions
    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    @patients = patient.active_dependents.uniq.map do |dependent|
      { patient: dependent, jurisdiction_unique_id: Jurisdiction.find_by_id(dependent.jurisdiction_id).unique_identifier }
    end
    @lang = patient.select_language(:email)
    @contact_info = patient.jurisdiction.contact_info
    mail(to: patient.email&.strip, subject: I18n.t('assessments.html.email.enrollment.subject', locale: @lang)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    History.welcome_message_sent(patient: patient)
  end

  def enrollment_sms_weblink(patient)
    enrollment_sms_text_based(patient)
  end

  def enrollment_sms_text_based(patient)
    # Should not be sending enrollment sms if no valid number
    return if patient&.primary_telephone.blank?

    if patient.blocked_sms
      TwilioSender.handle_twilio_error_codes(patient, TwilioSender::TWILIO_ERROR_CODES[:blocked_number][:code])
      return
    end

    lang = patient.select_language(:sms)
    contents = I18n.t('assessments.twilio.sms.prompt.intro', locale: lang, name: patient&.initials_age('-'))
    threshold_hash = patient.jurisdiction[:current_threshold_condition_hash]
    message = { prompt: contents, patient_submission_token: patient.submission_token, threshold_hash: threshold_hash }
    success = TwilioSender.send_sms(patient, [message])
    History.welcome_message_sent(patient: patient) if success

    # Always update the last contact time so the system does not try and send sms again.
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end

  # Right now the wording of this message is the same as for enrollment
  def assessment_sms_weblink(patient)
    if patient&.primary_telephone.blank?
      add_fail_history_blank_field(patient, 'primary phone number')
      return
    end
    if patient.blocked_sms
      TwilioSender.handle_twilio_error_codes(patient, TwilioSender::TWILIO_ERROR_CODES[:blocked_number][:code])
      return
    end

    # Cover potential race condition where multiple messages are sent for the same monitoree.
    return unless patient.last_assessment_reminder_sent_eligible?

    messages_array = []
    sms_lang = patient.select_language(:sms)
    web_lang = patient.select_language(:email)
    patient.active_dependents.uniq.each do |dependent|
      url = new_patient_assessment_jurisdiction_lang_initials_url(dependent.submission_token, dependent.jurisdiction.unique_identifier, web_lang&.to_s,
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
    patient.active_dependents_and_self.each { |pat| add_success_history(pat) } if TwilioSender.send_sms(patient, messages_array)
  end

  def assessment_sms(patient)
    if patient&.primary_telephone.blank?
      add_fail_history_blank_field(patient, 'primary phone number')
      return
    end
    if patient.blocked_sms
      TwilioSender.handle_twilio_error_codes(patient, TwilioSender::TWILIO_ERROR_CODES[:blocked_number][:code])
      return
    end

    # Cover potential race condition where multiple messages are sent for the same monitoree.
    return unless patient.last_assessment_reminder_sent_eligible?

    lang = patient.select_language(:sms)
    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    patient_names = patient.active_dependents.uniq.map do |dependent|
      I18n.t('assessments.twilio.sms.prompt.name', locale: lang, name: dependent&.initials_age('-'))
    end

    # Prepare text asking about anyone in the group
    plural = patient.active_dependents.uniq.count > 1

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    symptom_names = patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang)

    # Construct message contents
    experiencing_symptoms = I18n.t("assessments.twilio.shared.experiencing_symptoms_#{plural ? 'p' : 's'}", locale: lang, name: patient.initials,
                                                                                                            symptom_names: symptom_names)
    contents = I18n.t('assessments.twilio.sms.prompt.daily', locale: lang, names: patient_names.join(', '), experiencing_symptoms: experiencing_symptoms)

    threshold_hash = patient.jurisdiction[:current_threshold_condition_hash]
    # The medium parameter will either be SMS, VOICE or SINGLE_SMS
    params = { prompt: contents, patient_submission_token: patient.submission_token,
               threshold_hash: threshold_hash, medium: 'SMS', language: lang.to_s.split('-').first.upcase,
               try_again: I18n.t('assessments.twilio.sms.prompt.try_again', locale: lang),
               max_retries_message: I18n.t('assessments.twilio.shared.max_retries_message', locale: lang),
               thanks: I18n.t('assessments.twilio.sms.prompt.thanks', locale: lang) }
    # Update last send attempt timestamp before Twilio sms assessment
    patient.last_assessment_reminder_sent = DateTime.now
    patient.save(touch: false)
    patient.active_dependents_and_self.each { |pat| add_success_history(pat) } if TwilioSender.start_studio_flow_assessment(patient, params)
  end

  def assessment_voice(patient)
    if patient&.primary_telephone.blank?
      add_fail_history_blank_field(patient, 'primary phone number')
      return
    end

    # Cover potential race condition where multiple messages are sent for the same monitoree.
    return unless patient.last_assessment_reminder_sent_eligible?

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

    threshold_hash = patient.jurisdiction[:current_threshold_condition_hash]
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
    patient.active_dependents_and_self.each { |pat| add_success_history(pat) } if TwilioSender.start_studio_flow_assessment(patient, params)
  end

  def assessment_email(patient)
    if patient&.email.blank?
      add_fail_history_blank_field(patient, 'email')
      return
    end

    # Cover potential race condition where multiple messages are sent for the same monitoree.
    # Do not send an assessment when patient's last_assessment_reminder_sent is set or a reminder was sent less than 12 hours ago.
    return unless patient.last_assessment_reminder_sent_eligible?

    @lang = patient.select_language(:email)
    @contact_info = patient.jurisdiction.contact_info
    # Gather patients and jurisdictions
    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    @patients = patient.active_dependents.uniq.map do |dependent|
      { patient: dependent, jurisdiction_unique_id: Jurisdiction.find_by_id(dependent.jurisdiction_id).unique_identifier }
    end
    # Update last send attempt timestamp before SMTP call
    patient.last_assessment_reminder_sent = DateTime.now
    patient.save(touch: false)
    mail(to: patient.email&.strip, subject: I18n.t('assessments.html.email.reminder.subject', locale: @lang)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    patient.active_dependents_and_self.each { |pat| add_success_history(pat) }
  # This method is called in in the main loop of the send_assessments_job
  # It is important to capture and log all errors and let the loop continue to send assessments
  rescue StandardError => e
    # Reset send attempt timestamp on failure
    patient.last_assessment_reminder_sent = nil
    patient.save(touch: false)
    # report_email_error History will not update associated patient updated_at
    History.report_email_error(patient: patient)
    Raven.capture_exception(e)
  end

  def closed_email(patient)
    if patient&.email.blank?
      History.send_close_conact_method_blank(patient: patient, type: 'email')
      return
    end

    @lang = patient.select_language(:email)
    @contents = I18n.t(
      'assessments.html.email.closed.thank_you',
      initials_age: patient&.initials_age('-'),
      completed_date: patient.closed_at&.strftime('%m-%d-%Y'),
      locale: @lang
    )
    mail(to: patient.email&.strip, subject: I18n.t('assessments.html.email.closed.subject', locale: @lang)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    History.monitoring_complete_message_sent(patient: patient)
  end

  def closed_sms(patient)
    if patient&.primary_telephone.blank?
      History.send_close_conact_method_blank(patient: patient, type: 'primary phone number')
      return
    end
    if patient.blocked_sms
      History.send_close_sms_blocked(patient: patient)
      return
    end

    lang = patient.select_language(:sms)
    contents = I18n.t(
      'assessments.twilio.sms.closed.thank_you',
      initials_age: patient&.initials_age('-'),
      completed_date: patient.closed_at&.strftime('%m-%d-%Y'),
      locale: lang
    )
    message = {
      prompt: contents,
      patient_submission_token: patient.submission_token,
      threshold_hash: patient.jurisdiction[:current_threshold_condition_hash]
    }
    TwilioSender.send_sms(patient, [message])
    History.monitoring_complete_message_sent(patient: patient)
  end

  private

  def add_success_history(patient)
    comment = if patient.id == patient.responder_id
                "Sara Alert sent a report reminder to this monitoree via #{patient.preferred_contact_method}."
              else
                "Sara Alert sent a report reminder to this monitoree's head of household via #{patient.responder.preferred_contact_method}."
              end
    History.report_reminder(patient: patient, comment: comment)
  end

  def add_fail_history_blank_field(patient, type)
    History.unsuccessful_report_reminder(patient: patient,
                                         comment: "Sara Alert could not send a report reminder to this monitoree via \
                                     #{patient.preferred_contact_method}, because the monitoree #{type} was blank.")
  end
end
