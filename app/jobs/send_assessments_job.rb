# frozen_string_literal: true

# SendAssessmentsJob: sends assessment reminder to patients
class SendAssessmentsJob < ApplicationJob
  queue_as :mailers

  def perform(*_args)
    patient_ids = Patient.reminder_eligible.pluck(:id)
    eligible = patient_ids.size
    results = perform_batch(patient_ids)
    UserMailer.assessment_job_email(results[:sent], results[:not_sent], eligible).deliver_now
  end

  private

  def perform_batch(patient_batch)
    sent = []
    not_sent = []
    Patient.select(
      :id,
      :email,
      :preferred_contact_method,
      :monitored_address_state,
      :address_state,
      :last_assessment_reminder_sent,
      :preferred_contact_time,
      :last_date_of_exposure,
      :created_at,
      :monitoring,
      :isolation,
      :continuous_exposure
    ).where(id: patient_batch).find_in_batches(batch_size: 15_000) do |group|
      group.each do |patient|
        sent << { id: patient.id, method: patient.preferred_contact_method } if patient.send_assessment
      rescue StandardError => e
        not_sent << { id: patient.id, method: patient.preferred_contact_method, reason: e.message }
      end
    end
    {
      sent: sent,
      not_sent: not_sent
    }
  end

  # def combine_batch_results(batch_results)
  #   results = {
  #     sent: [],
  #     not_sent: []
  #   }
  #   batch_results.each do |batch_result|
  #     results[:sent] += batch_result[:sent]
  #     results[:not_sent] += batch_result[:not_sent]
  #   end
  #   results
  # end
end
