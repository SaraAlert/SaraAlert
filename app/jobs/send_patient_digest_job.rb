# frozen_string_literal: true

# SendPatientDigestJob: sends assessment reminder to patients
class SendPatientDigestJob < ApplicationJob
    queue_as :mailers
  
    def perform(*_args)
        jurisdiction_ids = []
        jurisdiction_lists = {}
        jurisdiction_addressees = {}
        puts "in here!"
        Jurisdiction.find_each do |jur|
            if jur.send_digest
                puts "in the conditional!"
                jurisdiction_ids << jur.id
                jurisdiction_patients = jur.all_patients.recently_symptomatic
                jurisdiction_addressees = User.where(jurisdiction_id: jur.id)
                jurisdiction_addressees.each do |user|
                    eligible = jurisdiction_patients.count
                    UserMailer.send_patient_digest_job_email(jurisdiction_patients, user, eligible).deliver_now
                end
            end
        end
  end
end