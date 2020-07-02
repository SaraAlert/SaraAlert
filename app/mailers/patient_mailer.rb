# frozen_string_literal: true

# PatientMailer: mailers for monitorees
class PatientMailer < ApplicationMailer
  default from: 'notifications@saraalert.org'

  def enrollment_email(patient)
    return if patient&.email.blank?

    # Gather patients and jurisdictions
    @patients = ([patient] + patient.dependents).uniq.collect do |p|
      { patient: p, jurisdiction_unique_id: Jurisdiction.find_by_id(p.jurisdiction_id).unique_identifier }
    end
    @lang = patient.select_language
    mail(to: patient.email&.strip, subject: I18n.t('assessments.email.enrollment.subject', locale: @lang)) do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  def enrollment_sms_weblink(patient)
    return if patient&.primary_telephone.blank?

    lang = patient.select_language
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.calc_current_age || '0'}"
    intro_contents = "#{I18n.t('assessments.sms.weblink.intro1', locale: lang)} #{patient_name} #{I18n.t('assessments.sms.weblink.intro2', locale: lang)}"
    url_contents = new_patient_assessment_jurisdiction_report_lang_url(patient.submission_token,
                                                                       lang&.to_s || 'en',
                                                                       patient.jurisdiction.unique_identifier[0, 32]).to_s
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: intro_contents
    )
    client.messages.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: url_contents
    )
  rescue Twilio::REST::RestError => e
    Rails.logger.warn e.error_message
    add_history_failed_sms(patient)
  end

  def enrollment_sms_text_based(patient)
    return if patient&.primary_telephone.blank?

    lang = patient.select_language
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.calc_current_age || '0'}"
    contents = "#{I18n.t('assessments.sms.prompt.intro1', locale: lang)} #{patient_name} #{I18n.t('assessments.sms.prompt.intro2', locale: lang)}"
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: contents
    )
  rescue Twilio::REST::RestError => e
    Rails.logger.warn e.error_message
    add_history_failed_sms(patient)
  end

  # Right now the wording of this message is the same as for enrollment
  def assessment_sms_weblink(patient)
    add_fail_history_blank_field(patient, 'primary phone number') && return if patient&.primary_telephone.blank?

    num = patient.primary_telephone
    ([patient] + patient.dependents).uniq.each do |p|
      lang = p.select_language
      patient_name = "#{p&.first_name&.first || ''}#{p&.last_name&.first || ''}-#{p&.calc_current_age || '0'}"
      intro_contents = "#{I18n.t('assessments.sms.weblink.intro1', locale: lang)} #{patient_name} #{I18n.t('assessments.sms.weblink.intro2', locale: lang)}"
      url_contents = new_patient_assessment_jurisdiction_report_lang_url(p.submission_token,
                                                                         lang&.to_s || 'en',
                                                                         patient.jurisdiction.unique_identifier[0, 32]).to_s
      account_sid = ENV['TWILLIO_API_ACCOUNT']
      auth_token = ENV['TWILLIO_API_KEY']
      from = ENV['TWILLIO_SENDING_NUMBER']
      client = Twilio::REST::Client.new(account_sid, auth_token)
      client.messages.create(
        from: from,
        to: Phonelib.parse(num, 'US').full_e164,
        body: intro_contents
      )
      client.messages.create(
        from: from,
        to: Phonelib.parse(num, 'US').full_e164,
        body: url_contents
      )
      add_success_history(p)
    end
  rescue Twilio::REST::RestError => e
    Rails.logger.warn e.error_message
    add_history_failed_sms(patient)
  end

  def assessment_sms_reminder(patient)
    add_fail_history_blank_field(patient, 'primary phone number') && return if patient&.primary_telephone.blank?

    lang = patient.select_language
    contents = I18n.t('assessments.sms.prompt.reminder', locale: lang)
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: contents
    )
    add_success_history(patient)
  rescue Twilio::REST::RestError => e
    Rails.logger.warn e.error_message
    add_history_failed_sms(patient)
  end

  def assessment_sms(patient)
    add_fail_history_blank_field(patient, 'primary phone number') && return if patient&.primary_telephone.blank?

    lang = patient.select_language
    patient_names = ([patient] + patient.dependents).uniq.collect do |p|
      "#{p&.first_name&.first || ''}#{p&.last_name&.first || ''}-#{p&.calc_current_age || '0'}"
    end
    contents = I18n.t('assessments.sms.prompt.daily1', locale: lang) + patient_names.join(', ') + '.'

    # Prepare text asking about anyone in the group
    contents += if ([patient] + patient.dependents).uniq.count > 1
                  I18n.t('assessments.sms.prompt.daily2-p', locale: lang)
                else
                  I18n.t('assessments.sms.prompt.daily2-s', locale: lang)
                end

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    contents += I18n.t('assessments.sms.prompt.daily3', locale: lang) + patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang) + '.'
    contents += I18n.t('assessments.sms.prompt.daily4', locale: lang)
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token,
               threshold_hash: threshold_hash, medium: 'SMS', language: lang.to_s.split('-').first.upcase }
    client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      parameters: params
    )
    add_success_history(patient)
  rescue Twilio::REST::RestError => e
    Rails.logger.warn e.error_message
    add_history_failed_sms(patient)
  end

  def assessment_voice(patient)
    add_fail_history_blank_field(patient, 'primary phone number') && return if patient&.primary_telephone.blank?

    lang = patient.select_language
    lang = :en %i[so].include?(lang) # Some languages are not supported via voice
    patient_names = ([patient] + patient.dependents).uniq.collect do |p|
      "#{p&.first_name&.first || ''}, #{p&.last_name&.first || ''}, #{I18n.t('assessments.phone.age', locale: lang)} #{p&.calc_current_age || '0'},"
    end
    contents = I18n.t('assessments.phone.daily1', locale: lang) + patient_names.join(', ')

    # Prepare text asking about anyone in the group
    contents += if ([patient] + patient.dependents).uniq.count > 1
                  I18n.t('assessments.phone.daily2-p', locale: lang)
                else
                  I18n.t('assessments.phone.daily2-s', locale: lang)
                end

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    contents += I18n.t('assessments.phone.daily3', locale: lang) + patient.jurisdiction.hierarchical_condition_bool_symptoms_string(lang) + '?'
    contents += I18n.t('assessments.phone.daily4', locale: lang)
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token,
               threshold_hash: threshold_hash, medium: 'VOICE', language: lang.to_s.split('-').first.upcase }
    client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      parameters: params
    )
    add_success_history(patient)
  rescue Twilio::REST::RestError => e
    Rails.logger.warn e.error_message
    add_history_failed_voice(patient)
  end

  def assessment_email(patient)
    add_fail_history_blank_field(patient, 'email') && return if patient&.email.blank?

    @lang = patient.select_language
    # Gather patients and jurisdictions
    @patients = ([patient] + patient.dependents).uniq.collect do |p|
      { patient: p, jurisdiction_unique_id: Jurisdiction.find_by_id(p.jurisdiction_id).unique_identifier }
    end
    mail(to: patient.email&.strip, subject: I18n.t('assessments.email.reminder.subject', locale: @lang || :en)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    add_success_history(patient)
  end

  def closed_email(patient)
    return if patient&.email.blank?

    @patient = patient
    @lang = patient.select_language
    mail(to: patient.email&.strip, subject: I18n.t('assessments.email.closed.subject', locale: @lang || :en)) do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  private

  def add_success_history(patient)
    return if patient.nil?

    unless patient&.preferred_contact_method.nil?
      history = History.new
      history.created_by = 'Sara Alert System'
      comment = "Sara Alert sent a report reminder to this monitoree via #{patient.preferred_contact_method}."
      history.comment = comment
      history.patient = patient
      history.history_type = 'Report Reminder'
      history.save
    end
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end

  def add_fail_history_blank_field(patient, type)
    return if patient.nil?

    history = History.new
    history.created_by = 'Sara Alert System'
    comment = "Sara Alert could not send a report reminder to this monitoree via #{patient.preferred_contact_method}, because the monitoree #{type} was blank."
    history.comment = comment
    history.patient = patient
    history.history_type = 'Report Reminder'
    history.save
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end

  def add_history_failed_sms(patient)
    return if patient.nil?

    history = History.new
    history.created_by = 'Sara Alert System'
    comment = "Sara Alert failed to send an SMS to #{patient.primary_telephone}."
    history.comment = comment
    history.patient = patient
    history.history_type = 'Report Reminder'
    history.save
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end

  def add_history_failed_voice(patient)
    return if patient.nil?

    history = History.new
    history.created_by = 'Sara Alert System'
    comment = "Sara Alert failed to call monitoree at #{patient.primary_telephone}."
    history.comment = comment
    history.patient = patient
    history.history_type = 'Report Reminder'
    history.save
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end
end
