# frozen_string_literal: true

# SendPatientDigestJob: sends assessment reminder to patients
class SendPatientDigestJob < ApplicationJob
  queue_as :mailers

  def perform(*_args)
    jurisdiction_addressees = {}
    Jurisdiction.find_each do |jur|
      if jur.send_digest
        jurisdiction_patients = jur.all_patients.recently_symptomatic
        jurisdiction_addressees = User.where(jurisdiction_id: jur.id, role: ['super_user', 'public_health', 'public_health_enroller'])
        jurisdiction_addressees.each do |user|
          eligible = jurisdiction_patients.count
          UserMailer.send_patient_digest_job_email(jurisdiction_patients, user, eligible).deliver_now
        end
      end
    end
  end
end
