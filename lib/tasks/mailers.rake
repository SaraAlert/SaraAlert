# frozen_string_literal: true

namespace :mailers do
  desc 'Test sending an assessment reminder email'
  task test_send_assessment_reminder_email: :environment do
    user = User.new(email: 'foobar@foobar.foo', password: 'foobarfoobar2')
    test_patient = Patient.new(creator: user)
    test_patient.responder = test_patient
    test_patient.email = 'mmayer@mitre.org'
    test_patient.submission_token = SecureRandom.hex(20)
    test_patient.save!
    PatientMailer.assessment_email(test_patient).deliver_now
  end

  desc 'Test sending an enrollment email'
  task test_send_enrollment_email: :environment do
    user = User.new(email: 'foobar@foobar.foo', password: 'foobarfoobar2')
    test_patient = Patient.new(creator: user)
    test_patient.responder = test_patient
    test_patient.email = 'mmayer@mitre.org'
    test_patient.submission_token = SecureRandom.hex(20)
    test_patient.save!
    PatientMailer.enrollment_email(test_patient).deliver_now
  end
end
