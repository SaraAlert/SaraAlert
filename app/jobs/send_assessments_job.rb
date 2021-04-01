# frozen_string_literal: true

# SendAssessmentsJob: sends assessment reminder to patients
class SendAssessmentsJob < ApplicationJob
  queue_as :mailers

  def perform(*_args)
    patient_ids = Patient.reminder_eligible.pluck(:id)
    eligible = patient_ids.size

    # Check what the max thread pool is for the DB since that is the limiting factor
    # on how many threads can be used in the job. Subtracting 2 from the pool
    # size to be on the safer side of exhausting the connection pool.
    total_threads = [1, ActiveRecord::Base.connection_pool.stat[:size] - 2].max

    # [1, x].max here avoids an exception when there are 0 eligible patients
    slice_size = [1, patient_ids.size / total_threads].max

    threads = patient_ids.each_slice(slice_size).map do |patient_batch|
      Thread.new { perform_batch(patient_batch) }
    end
    threads.each(&:join)
    results = combine_batch_results(threads.map(&:value))
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

  def combine_batch_results(batch_results)
    results = {
      sent: [],
      not_sent: []
    }
    batch_results.each do |batch_result|
      results[:sent] += batch_result[:sent]
      results[:not_sent] += batch_result[:not_sent]
    end
    results
  end
end
