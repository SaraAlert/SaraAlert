# frozen_string_literal: true

# PatientMailer: mailers for monitorees
class PatientMailer < ApplicationMailer
  default from: 'notifications@saraalert.org'

  def enrollment_email(patient)
    return if patient&.email&.blank?
    add_success_history(patient)
    # Gather patients and jurisdictions
    @patients = ([patient] + patient.dependents).uniq.collect do |p|
      { patient: p, jurisdiction_unique_id: Jurisdiction.find_by_id(p.jurisdiction_id).unique_identifier }
    end
    mail(to: patient.email, subject: 'Sara Alert Enrollment') do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  def enrollment_sms_weblink(patient)
    return if patient&.primary_telephone&.blank?
    add_success_history(patient)
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.calc_current_age || '0'}"
    contents = "This is the Sara Alert system please complete the report for #{patient_name} at "
    contents += new_patient_assessment_jurisdiction_report_url(patient.submission_token, patient.jurisdiction.unique_identifier).to_s
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: contents
    )
  end

  def enrollment_sms_text_based(patient)
    return if patient&.primary_telephone&.blank?
    add_success_history(patient)
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.calc_current_age || '0'}"
    contents = "Welcome to the Sara Alert system, we will be sending your daily reports for #{patient_name} to this phone number."
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: contents
    )
  end

  # Right now the wording of this message is the same as for enrollment
  def assessment_sms_weblink(patient)
    add_fail_history(patient, 'primary phone number') && return if patient&.primary_telephone&.blank?
    add_success_history(patient)
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.calc_current_age || '0'}"
    contents = "This is the Sara Alert system please complete the daily report for #{patient_name} at "
    contents += new_patient_assessment_jurisdiction_report_url(patient.submission_token, patient.jurisdiction.unique_identifier).to_s
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: contents
    )
  end

  def assessment_sms_reminder(patient)
    add_fail_history(patient, 'primary phone number') && return if patient&.primary_telephone&.blank?
    add_success_history(patient)
    contents = 'This is the Sara Alert system reminding you to please reply to our daily-report messages.'
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: contents
    )
  end

  def assessment_sms(patient)
    add_fail_history(patient, 'primary phone number') && return if patient&.primary_telephone&.blank?
    add_success_history(patient)
    patient_names = ([patient] + patient.dependents).uniq.collect do |p|
      "#{p&.first_name&.first || ''}#{p&.last_name&.first || ''}-#{p&.calc_current_age || '0'}"
    end
    contents = 'This is the Sara Alert daily report for: ' + patient_names.to_sentence

    # Prepare text asking about anyone in the group
    contents += if ([patient] + patient.dependents).uniq.count > 1
                  ' Are any of these people '
                else
                  ' Is this person '
                end

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    contents += 'experiencing any of the following symptoms ' + patient.jurisdiction.hierarchical_condition_bool_symptoms_string + '?'
    contents += ' Please reply with "Yes" or "No"'
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token, threshold_hash: threshold_hash, medium: 'SMS' }
    client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      parameters: params
    )
  end

  def assessment_voice(patient)
    add_fail_history(patient, 'primary phone number') && return if patient&.primary_telephone&.blank?
    add_success_history(patient)
    patient_names = ([patient] + patient.dependents).uniq.collect do |p|
      "#{p&.first_name&.first || ''}, #{p&.last_name&.first || ''}, Age #{p&.calc_current_age || '0'},"
    end
    contents = ' This is the report for: ' + patient_names.to_sentence

    # Prepare text asking about anyone in the group
    contents += if ([patient] + patient.dependents).uniq.count > 1
                  ' Are any of these people '
                else
                  ' Is this person '
                end

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    contents += 'experiencing any of the following symptoms, ' + patient.jurisdiction.hierarchical_condition_bool_symptoms_string + '?'
    contents += ' Please reply with "Yes" or "No"'
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token, threshold_hash: threshold_hash, medium: 'VOICE' }
    client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
      from: from,
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      parameters: params
    )
  end

  def assessment_email(patient)
    add_fail_history(patient, 'email') && return if patient&.email&.blank?
    add_success_history(patient)
    # Gather patients and jurisdictions
    @patients = ([patient] + patient.dependents).uniq.collect do |p|
      { patient: p, jurisdiction_unique_id: Jurisdiction.find_by_id(p.jurisdiction_id).unique_identifier }
    end
    mail(to: patient.email, subject: 'Sara Alert Report Reminder') do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  def closed_email(patient)
    return if patient&.email&.blank?
    add_success_history(patient)
    @patient = patient
    mail(to: patient.email, subject: 'Sara Alert Reporting Complete') do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  private

  def add_success_history(patient)
    return if patient.nil?
    unless patient&.preferred_contact_method&.nil?
      history = History.new
      history.created_by = 'Sara Alert System'
      comment = 'Sara Alert sent a report reminder to this monitoree via ' + patient.preferred_contact_method + '.'
      history.comment = comment
      history.patient = patient
      history.history_type = 'Report Reminder'
      history.save
    end
    patient.update(last_assessment_reminder_sent: DateTime.now)
  end

  def add_fail_history(patient, type)
    return if patient.nil?
    history = History.new
    history.created_by = 'Sara Alert System'
    comment = "Sara Alert could not send a report reminder to this monitoree via #{patient.preferred_contact_method}, because the monitoree #{type} was blank."
    history.comment = comment
    history.patient = patient
    history.history_type = 'Report Reminder'
    history.save
  end
end
