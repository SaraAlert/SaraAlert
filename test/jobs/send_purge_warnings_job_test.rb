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
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, 'Sara Alert Send Purge Warnings Job Results')
  end
end
