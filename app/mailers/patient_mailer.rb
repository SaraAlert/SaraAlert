class PatientMailer < ApplicationMailer
  default from: 'notifications@diseaseTrakker.org'
   
  def assessment_email(patient)
    @patient = patient
    mail(to: patient.email, subject: 'DiseaseTrackker Assessment Reminder')
  end

  def enrollment_email(patient)
    @patient = patient
    mail(to: patient.email, subject: 'DiseaseTrackker Enrollment')
  end
end
