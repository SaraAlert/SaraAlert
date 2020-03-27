# frozen_string_literal: true

# PatientMailer: mailers for monitorees
class PatientMailer < ApplicationMailer
  default from: 'notifications@SaraAlert.mitre.org'

  def enrollment_email(patient)
    # Gather patients and jurisdictions
    @patients = ([patient] + patient.dependents).uniq.collect do |p|
      { patient: p, jurisdiction_unique_id: Jurisdiction.find_by_id(p.jurisdiction_id).unique_identifier }
    end
    mail(to: patient.email, subject: 'Sara Alert Enrollment')
  end

  def enrollment_sms_weblink(patient)
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.age || '0'}"
    contents = "This is the Sara Alert system please complete the report for #{patient_name} at "
    contents += new_patient_assessment_jurisdiction_report_url(patient.submission_token, patient.jurisdiction.unique_identifier).to_s
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: patient.primary_telephone,
      body: contents
    )
  end

  def enrollment_sms_text_based(patient)
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.age || '0'}"
    contents = "Welcome to the Sara Alert system, we will be sending your daily reports for #{patient_name} to this phone number."
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: patient.primary_telephone,
      body: contents
    )
  end

  # Right now the wording of this message is the same as for enrollment
  def assessment_sms_weblink(patient)
    patient_name = "#{patient&.first_name&.first || ''}#{patient&.last_name&.first || ''}-#{patient&.age || '0'}"
    contents = "This is the Sara Alert system please complete the daily report for #{patient_name} at "
    contents += new_patient_assessment_jurisdiction_report_url(patient.submission_token, patient.jurisdiction.unique_identifier).to_s
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    client.messages.create(
      from: from,
      to: patient.primary_telephone,
      body: contents
    )
  end

  def assessment_sms(patient)
    patient_names = ([patient] + patient.dependents).uniq.collect do |p|
      "#{p&.first_name&.first || ''}#{p&.last_name&.first || ''}-#{p&.age || '0'}"
    end
    contents = 'This is the SaraAlert daily report for: ' + patient_names.to_sentence

    # Prepare text asking about anyone in the group
    contents += if ([patient] + patient.dependents).uniq.count > 1
                  ' Are any of these people '
                else
                  ' Is this person '
                end

    # This assumes that all of the dependents will be in the same jurisdiction and therefore have the same symptom questions
    # If the dependets are in a different jurisdiction they may end up with too many or too few symptoms in their response
    contents += 'experiencing any of the following symptoms ' + patient.jurisdiction.hierarchical_condition_bool_symptoms_string + '?'
    contents += ' Please reply with Yes or No'
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    post_url = root_url + "report/patients/#{patient.submission_token}/assessments"
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token, threshold_hash: threshold_hash, post_url: post_url, medium: 'SMS' }
    client.studio.v1.flows('FW6e9479580a8040dbdfed3b057d244534').executions.create(
      from: from,
      to: patient.primary_telephone,
      parameters: params
    )
  end

  def assessment_voice(patient)
    patient_names = ([patient] + patient.dependents).uniq.collect do |p|
      "#{p&.first_name&.first || ''}, #{p&.last_name&.first || ''}, Age #{p&.age || '0'},"
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
    contents += ' Please reply with Yes or No'
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)
    threshold_hash = patient.jurisdiction.jurisdiction_path_threshold_hash
    post_url = root_url + "report/patients/#{patient.submission_token}/assessments"
    # The medium parameter will either be SMS or VOICE
    params = { prompt: contents, patient_submission_token: patient.submission_token, threshold_hash: threshold_hash, post_url: post_url, medium: 'VOICE' }
    client.studio.v1.flows('FW6e9479580a8040dbdfed3b057d244534').executions.create(
      from: from,
      to: patient.primary_telephone,
      parameters: params
    )
  end

  def assessment_email(patient)
    # Gather patients and jurisdictions
    @patients = ([patient] + patient.dependents).uniq.collect do |p|
      { patient: p, jurisdiction_unique_id: Jurisdiction.find_by_id(p.jurisdiction_id).unique_identifier }
    end
    mail(to: patient.email, subject: 'Sara Alert Report Reminder')
  end

  def closed_email(patient)
    @patient = patient
    mail(to: patient.email, subject: 'Sara Alert Reporting Complete')
  end
end
