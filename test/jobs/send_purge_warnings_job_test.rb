# frozen_string_literal: true

require 'test_case'

class SendPurgeWarningsJobTest < ActiveSupport::TestCase
  def setup
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
  end

  def teardown
    ADMIN_OPTIONS['job_run_email'] = nil
  end

  test 'sends an purge notification job email with user IDs of users sent notification email' do
    email = SendPurgeWarningsJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, 'Sara Alert Send Purge Warnings Job Results')
  end

  test 'sends emails to each admin user not in the USA jurisdiction' do
  end

  test 'sends correct email when no purge eligible monitorees for user' do
  end

  test 'sends correct email when there are purge eligible monitorees for user' do
  end
end
