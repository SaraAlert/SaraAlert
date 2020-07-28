# frozen_string_literal: true

# SendAssessmentsJob: sends assessment reminder to patients
class SendAssessmentsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    ids = []
    Patient.reminder_eligible_exposure.find_each(batch_size: 50_000) do |patient|
      ids << patient.send_assessment
    end
    Patient.reminder_eligible_isolation.find_each(batch_size: 50_000) do |patient|
      ids << patient.send_assessment
    end
    # Update last_assessment_reminder_sent for all patients that were just sent a daily
    # report notification (by rejecting nils, we remove patients who were sent nothing).
    Patient.where(id: ids.reject(&:nil?)).update_all(last_assessment_reminder_sent: DateTime.now)
  end
end
