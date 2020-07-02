# frozen_string_literal: true

# SendAssessmentsJob: sends assessment reminder to patients
class SendAssessmentsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Patient.reminder_eligible_exposure.find_each(batch_size: 5000, &:send_assessment)
    Patient.reminder_eligible_isolation.find_each(batch_size: 5000, &:send_assessment)
  end
end
