# frozen_string_literal: true

# SendPurgeWarningsJob: sends purge warning reminder to admins
class SendPurgeWarningsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    sent = []
    not_sent = []

    # Get admin users but skip USA admins and locked users
    recipients = User.where(role: [Roles::ADMIN, Roles::SUPER_USER], locked_at: nil).where.not(jurisdiction: Jurisdiction.root)
    eligible = recipients.count

    # Loop through and send each admin information about their purge eligible monitorees
    recipients.each do |user|
      # Get num purgeable underneath this admin's purview
      num_purgeable_records = user.viewable_patients.purge_eligible.size

      # Send email to use with info
      UserMailer.purge_notification(user, num_purgeable_records).deliver_later

      sent << { id: user.id }
    rescue StandardError => e
      not_sent << { id: user.id, reason: e.message }
    end

    UserMailer.send_purge_warnings_job_email(sent, not_sent, eligible).deliver_now
  end
end
