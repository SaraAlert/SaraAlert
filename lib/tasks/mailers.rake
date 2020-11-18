# frozen_string_literal: true

namespace :mailers do
  desc 'Test sending an assessment reminder email'
  task test_send_assessment_reminder_email: :environment do
    user = User.new(email: 'foobar@foobar.foo', password: 'foobarfoobar2')
    test_patient = Patient.new(creator: user)
    test_patient.responder = test_patient
    test_patient.email = '<test_email>'
    test_patient.submission_token = SecureRandom.urlsafe_base64[0, 10]
    test_patient.save!
    PatientMailer.assessment_email(test_patient).deliver_now
  end

  desc 'Test sending an enrollment email'
  task test_send_enrollment_email: :environment do
    user = User.new(email: 'foobar@foobar.foo', password: 'foobarfoobar2')
    test_patient = Patient.new(creator: user)
    test_patient.responder = test_patient
    test_patient.email = '<test_email>'
    test_patient.submission_token = SecureRandom.urlsafe_base64[0, 10]
    test_patient.save!
    PatientMailer.enrollment_email(test_patient).deliver_now
  end

  desc "Test making an assessment sms"
  task test_assessment_sms: :environment do
    # patient = Patient.first.dup
    # patient.first_name = "Test"
    # patient.last_name = "McTest"
    # patient.primary_language = "Spanish"
    # patient.age = 27
    # patient.primary_telephone = <Test Number in E164 format>
    # patient.save!
    PatientMailer.assessment_sms(patient).deliver_now
  end

  desc "Test making an assessment phone call"
  task test_assessment_voice: :environment do
    # patient = Patient.first.dup
    # patient.first_name = "Test"
    # patient.last_name = "McTest"
    # patient.primary_language = "Spanish"
    # patient.age = 27
    # patient.primary_telephone = <Test Number in E164 format>
    # patient.save
    PatientMailer.assessment_voice(patient).deliver_now
  end

  desc "Send Assessments and Assessment Reminders To Non-Reporting Individuals"
  task send_assessments: :environment do
    SendAssessmentsJob.perform_later
  end

  desc "Sends data purge warning to users"
  task send_purge_warning: :environment do
    SendPurgeWarningsJob.perform_later
  end
  
  desc "Sends patient digest to users"
  task send_patient_digest: :environment do
    SendPatientDigestJob.perform_later
  end
end
