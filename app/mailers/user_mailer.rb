# frozen_string_literal: true

require 'chronic'

# UserMailer: mailers for users
class UserMailer < ApplicationMailer
  default from: 'notifications@saraalert.org'

  def assessment_job_email(sent, not_sent, eligible)
    @sent = sent
    @not_sent = not_sent
    @eligible = eligible
    mail(to: ADMIN_OPTIONS['job_run_email'], subject: "Sara Alert Send Assessments Job Results (#{ActionMailer::Base.default_url_options[:host]})")
  end

  def download_email(user, export_type, lookups)
    @user = user
    @export_type = export_type
    @lookups = lookups
    mail(to: user.email.strip, subject: 'Your Sara Alert system export is ready') do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  def welcome_email(user, password)
    @user = user
    @password = password
    mail(to: user.email.strip, subject: 'Welcome to the Sara Alert system') do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  def admin_message_email(user, comment)
    @comment = comment
    mail(to: user.email.strip, subject: 'Message from the Sara Alert system') do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  def purge_notification
    recipients = User.with_any_role(:admin)
    @expiration_date = Chronic.parse(ADMIN_OPTIONS['weekly_purge_date']).strftime('%A %B %d, at %l:%M %p %Z')

    recipients.each do |user|
      next if user.jurisdiction&.name == 'USA'

      @user = user
      @num_purgeable_records = user.viewable_patients.purge_eligible.size

      subject = @num_purgeable_records.zero? ? 'Sara Alert Notification' : 'Sara Alert User Records Expiring Soon'

      mail(to: user.email.strip, subject: subject) do |format|
        format.html { render layout: 'main_mailer' }
      end
    end
  end
end
