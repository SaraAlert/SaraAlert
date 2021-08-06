# frozen_string_literal: true

require 'test_case'

# IMPORTANT NOTE ON CHANGES TO Time.now CALLS IN THIS FILE
# Updated Time.now to Time.now.getlocal for Rails/TimeZone because Time.now defaulted to a zone. In this case it was the developer machine or CI/CD server zone.
class JwtIdentifierTest < ActiveSupport::TestCase
  def setup
    @oauth_app = OauthApplication.create!(name: 'test-app', redirect_uri: 'urn:ietf:wg:oauth:2.0:oob')
  end

  def teardown
    @oauth_app.destroy
  end

  test 'create JWT Identifier' do
    assert create(:jwt_identifier, value: 'a', expiration_date: Time.now.getlocal, application_id: @oauth_app.id)
  end

  test 'purge eligible scope' do
    # JWT that expired two minutes ago SHOULD be purge eligible
    create(:jwt_identifier, value: 'a', expiration_date: Time.now.getlocal - 2.minutes, application_id: @oauth_app.id)
    assert_equal(1, JwtIdentifier.purge_eligible.count)

    # JWT that expired now SHOULD be purge eligible
    create(:jwt_identifier, value: 'b', expiration_date: Time.now.getlocal, application_id: @oauth_app.id)
    assert_equal(2, JwtIdentifier.purge_eligible.count)

    # Delete purge eligible before the next steps
    JwtIdentifier.delete_all

    # JWT that expires in 30 seconds should NOT be purge eligible
    create(:jwt_identifier, value: 'c', expiration_date: Time.now.getlocal + 30.seconds, application_id: @oauth_app.id)
    assert_equal(0, JwtIdentifier.purge_eligible.count)

    # JWT that expires in 5 minutes should NOT be purge eligible
    create(:jwt_identifier, value: 'd', expiration_date: Time.now.getlocal + 1.day, application_id: @oauth_app.id)
    assert_equal(0, JwtIdentifier.purge_eligible.count)
  end
end
