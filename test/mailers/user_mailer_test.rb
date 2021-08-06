# frozen_string_literal: true

require 'test_case'

class UserMailerTest < ActionMailer::TestCase
  def setup
    @user = create(:user)
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
  end

  def teardown
    ADMIN_OPTIONS['job_run_email'] = nil
  end

  test 'download email no lookups' do
    # When no monitorees match export criteria lookups = []
    email = UserMailer.download_email(@user, 'Export Label', []).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not(ActionMailer::Base.deliveries.empty?)
    assert_includes(email_body, 'Export Label')
    assert_includes(email_body, 'no monitorees or monitoree data matched the selected export criteria')
  end

  test 'purge_job email with all purged monitorees' do
    email = UserMailer.purge_job_email(
      [{ id: 9999 }],
      { current: 1, total: 1 },
      {
        start_time: 2.minutes.ago,
        end_time: 1.minute.ago,
        not_purged_count: 0,
        purged_count: 1
      }
    ).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not(ActionMailer::Base.deliveries.empty?)
    assert_includes(email_body, 'Purged during this job run: 1')
    assert_includes(email_body, '9999')
  end

  test 'purge_job email with all non purged monitorees' do
    email = UserMailer.purge_job_email(
      [{ id: 9999, reason: 'StandardError' }],
      { current: 1, total: 1 },
      {
        start_time: 2.minutes.ago,
        end_time: 1.minute.ago,
        not_purged_count: 1,
        purged_count: 0
      }
    ).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not(ActionMailer::Base.deliveries.empty?)
    assert_includes(email_body, 'Purged during this job run: 0')
    assert_includes(email_body, 'Not purged during this job run: 1')
    assert_includes(email_body, '9999, StandardError')
  end

  test 'purge_job email with no purged or non purged monitorees' do
    email = UserMailer.purge_job_email(
      [],
      { current: 1, total: 1 },
      {
        start_time: 2.minutes.ago,
        end_time: 1.minute.ago,
        not_purged_count: 0,
        purged_count: 0
      }
    ).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not(ActionMailer::Base.deliveries.empty?)
    assert_includes(email_body, 'Purged during this job run: 0')
    assert_includes(email_body, 'Not purged during this job run: 0')
  end

  test 'purge_job email with purged and non purged monitorees' do
    email = UserMailer.purge_job_email(
      [{ id: 9998 }, { id: 9999, reason: 'StandardError' }],
      { current: 1, total: 1 },
      {
        start_time: 2.minutes.ago,
        end_time: 1.minute.ago,
        not_purged_count: 1,
        purged_count: 1
      }
    ).deliver_now
    email_body = email.parts.first.body.to_s.tr("\n", ' ')
    assert_not(ActionMailer::Base.deliveries.empty?)
    assert_includes(email_body, 'Purged during this job run: 1')
    assert_includes(email_body, 'Not purged during this job run: 1')
    assert_includes(email_body, '9998')
    assert_includes(email_body, '9999, StandardError')
  end
end
