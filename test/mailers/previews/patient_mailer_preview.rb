# frozen_string_literal: true

class PatientMailerPreview < ActionMailer::Preview
  def enrollment_email
    PatientMailer.enrollment_email(Patient.first)
  end

  def assessment_email
    PatientMailer.assessment_email(Patient.first)
  end

  def closed_email
    PatientMailer.closed_email(Patient.first)
  end
end
