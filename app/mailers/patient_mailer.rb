class PatientMailer < ApplicationMailer
  default from: 'notifications@DiseaseTrakker.org'

  def assessment_email(patient)
    @patient = patient
    mail(to: patient.email, subject: 'DiseaseTrackker Assessment Reminder')
  end

  def enrollment_email(patient)
    @patient = patient
    mail(to: patient.email, subject: 'DiseaseTrackker Enrollment')
  end

  def enrollment_sms(patient)
    contents = "This is the DiseaseTrakker system please complete your assessment at #{new_patient_assessment_url(patient.submission_token)}"
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    client = Twilio::REST::Client.new(account_sid, auth_token)

    client.messages.create(
      from: from,
      to: patient.primary_phone,
      body: contents
    )
  end

end
