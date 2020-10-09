# frozen_string_literal: true

require 'test_case'

class PurgeJwtIdentifiersJobTest < ActiveSupport::TestCase
  def setup
    # Allowed to purge immediately for the tests
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
    @oauth_app = OauthApplication.create!(name: 'test-app', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob')
  end

  def teardown
    ADMIN_OPTIONS['job_run_email'] = nil
    @oauth_app.destroy
  end

  test 'sends an email with all purged JWT identifiers' do
    create(:jwt_identifier, value: 'a', expiration_date: Time.now - 1.day, application_id: @oauth_app.id)
    email = PurgeJwtIdentifiersJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, 'Total JWT Identifiers BEFORE purge: 1')
  end

  test 'deletes purge eligible JWT Identifiers' do
    create(:jwt_identifier, value: 'a', expiration_date: Time.now - 1.day, application_id: @oauth_app.id)
    create(:jwt_identifier, value: 'b', expiration_date: Time.now - 1.day, application_id: @oauth_app.id)
    create(:jwt_identifier, value: 'c', expiration_date: Time.now + 5.minutes, application_id: @oauth_app.id)

    PurgeJwtIdentifiersJob.perform_now
    # Should be one remaining since one out of the above was NOT purge eligible
    assert_equal(1, JwtIdentifier.count)
  end
end
