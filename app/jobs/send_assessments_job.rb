# frozen_string_literal: true

# SendAssessmentsJob: sends assessment reminder to patients
class SendAssessmentsJob < ApplicationJob
  queue_as :mailers

  def perform(*_args)
    eligible = Patient.reminder_eligible.count
    sent = []
    not_sent = []
    Patient.reminder_eligible.find_each do |patient|
      sent << { id: patient.id, method: patient.preferred_contact_method } if patient.send_assessment
    rescue StandardError => e
      not_sent << { id: patient.id, method: patient.preferred_contact_method, reason: e.message }
      next
    end
    UserMailer.assessment_job_email(sent, not_sent, eligible).deliver_now
  end
end
