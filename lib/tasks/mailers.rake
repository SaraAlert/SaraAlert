# frozen_string_literal: true

namespace :mailers do
  desc 'Test sending an assessment reminder email'
  task test_send_assessment_reminder_email: :environment do
    user = User.new(email: 'foobar@foobar.foo', password: 'foobarfoobar2')
    test_patient = Patient.new(creator: user)
    test_patient.responder = test_patient
    test_patient.email = '<test_email>'
    test_patient.submission_token = SecureRandom.hex(20)
    test_patient.save!
    PatientMailer.assessment_email(test_patient).deliver_now
  end

  desc 'Test sending an enrollment email'
  task test_send_enrollment_email: :environment do
    user = User.new(email: 'foobar@foobar.foo', password: 'foobarfoobar2')
    test_patient = Patient.new(creator: user)
    test_patient.responder = test_patient
    test_patient.email = '<test_email>'
    test_patient.submission_token = SecureRandom.hex(20)
    test_patient.save!
    PatientMailer.enrollment_email(test_patient).deliver_now
  end

  desc "Test making an assessment call"
  task test_asessment_call: :environment do
      account_sid = ENV['TWILLIO_API_ACCOUNT']
      auth_token = ENV['TWILLIO_API_KEY']
      from = ENV['TWILLIO_SENDING_NUMBER']
      twillio_client = Twilio::REST::Client.new(account_sid, auth_token)
      call = twillio_client.calls.create(
                             url: 'https://handler.twilio.com/twiml/EHf78be4930d246755333d60dc1cac708e',
                             to: '',
                             from: from
                           )

      puts call
  end

  desc "Test making an assessment sms"
  task test_asessment_sms: :environment do
    # patient = Patient.first.dup
    # patient.first_name = "Test"
    # patient.last_name = "McTest"
    # patient.age = 27
    # patient.primary_telephone = <Test Number in E164 format>
    # patient.save!
    PatientMailer.assessment_sms(patient).deliver_now
  end

  desc "Test making an assessment phone call"
  task test_asessment_voice: :environment do
    # patient = Patient.first.dup
    # patient.first_name = "Test"
    # patient.last_name = "McTest"
    # patient.age = 27
    # patient.primary_telephone = <Test Number in E164 format>
    # patient.save
    PatientMailer.assessment_voice(patient).deliver_now
  end


  desc "Send Assessments and Assessment Reminders To Non-Reporting Individuals"
  task send_assessments: :environment do
    Patient.non_reporting.each do |patient|
      patient.send_assessment
    end
  end

end
