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

  def purge_job_email(purged, not_purged, eligible)
    @purged = purged
    @not_purged = not_purged
    @eligible = eligible
    mail(to: ADMIN_OPTIONS['job_run_email'], subject: "Sara Alert Purge Job Results (#{ActionMailer::Base.default_url_options[:host]})")
  end

  def jwt_identifier_purge_job_email(total_before, eligible, total_after)
    @total_before = total_before
    @eligible = eligible
    @total_after = total_after
    mail(to: ADMIN_OPTIONS['job_run_email'], subject: "Sara Alert JWT Identifier Purge Job Results (#{ActionMailer::Base.default_url_options[:host]})")
  end

  def send_purge_warnings_job_email(sent, not_sent, eligible)
    @sent = sent
    @not_sent = not_sent
    @eligible = eligible
    mail(to: ADMIN_OPTIONS['job_run_email'], subject: "Sara Alert Send Purge Warnings Job Results (#{ActionMailer::Base.default_url_options[:host]})")
  end

  def close_job_email(closed, not_closed, eligible)
    @closed = closed
    @not_closed = not_closed
    @eligible = eligible
    mail(to: ADMIN_OPTIONS['job_run_email'], subject: "Sara Alert Close Job Results (#{ActionMailer::Base.default_url_options[:host]})")
  end

  def cache_analytics_job_email(cached, not_cached, eligible)
    return unless ADMIN_OPTIONS['job_run_email'].present?

    @cached = cached
    @not_cached = not_cached
    @eligible = eligible
    mail(to: ADMIN_OPTIONS['job_run_email'], subject: "Sara Alert Cache Analytics Job Results (#{ActionMailer::Base.default_url_options[:host]})")
  end

  def send_patient_digest_job_email(patients, user)
    @patients = patients
    mail(to: user.email.strip, subject: 'Sara Alert Monitoree Digest (last hour)') do |format|
      format.html { render layout: 'main_mailer' }
    end
  end

  def download_email(user, export_label, lookups, batch_size)
    @user = user
    @export_label = export_label
    @lookups = lookups
    @batch_size = batch_size
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

  def purge_notification(user, num_purgeable_records)
    @user = user
    @num_purgeable_records = num_purgeable_records
    @expiration_date = Chronic.parse(ADMIN_OPTIONS['weekly_purge_date']).strftime('%A %B %d, at %l:%M %p %Z')
    subject = @num_purgeable_records.zero? ? 'Sara Alert Notification' : 'Sara Alert User Records Expiring Soon'

    mail(to: user.email.strip, subject: subject) do |format|
      format.html { render layout: 'main_mailer' }
    end
  end
end
