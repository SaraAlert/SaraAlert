# frozen_string_literal: true

# SendPatientDigestJob: sends assessment reminder to patients
class SendPatientDigestJob < ApplicationJob
  queue_as :mailers

  def perform(*_args)
    sent = []
    jurisdictions = Jurisdiction.where(send_digest: true)

    # Loop over jurisdictions
    jurisdictions.each do |jur|
      # Grab patients who reported symtomatic in the last hour
      patients = jur.all_patients_excluding_purged.recently_symptomatic

      # Execute query, figure out how many meet requirements (if none skip email)
      next unless patients.size.positive?

      # Construct helper URLs
      patient_urls = patients.pluck(:id).collect { |p_id| "https://#{ActionMailer::Base.default_url_options[:host]}/patients/#{p_id}" }

      # Grab users who need an email
      users = User.where(jurisdiction_id: jur.id, role: %w[super_user public_health public_health_enroller])
      users.each do |user|
        # Send email to this user
        UserMailer.send_patient_digest_job_email(patient_urls, user).deliver_later
        sent << { id: user.id, jur_id: jur.id, user_jur_id: user.jurisdiction_id }
      end
    end

    # Send results email
    UserMailer.send_patient_digest_job_results_email(sent, jurisdictions.pluck(:id)).deliver_now
  end
end
