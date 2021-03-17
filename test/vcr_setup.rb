# frozen_string_literal: true

require 'vcr'
# VCR records HTTP interactions to cassettes that can be replayed during unit tests
# allowing for faster, more predictible web interactions
VCR.configure do |c|
  # This is where the various cassettes will be recorded to
  c.cassette_library_dir = 'test/vcr_cassettes'
  # This permits non-VCR webmock requests in other tests
  c.allow_http_connections_when_no_cassette = true
  c.hook_into :webmock

  # To avoid storing plain text Twilio API keys or requiring the keys
  # be provided at every run of the rake tests, provide the following credentials
  # whenever you need to record a cassette that requires valid credentials
  # these should be stored in your local_env.yml file anyhow
  ENV['TWILLIO_STUDIO_FLOW'] |= 'test_studio_flow'
  ENV['TWILLIO_MESSAGING_SERVICE_SID'] |= 'test_msg_service'
  ENV['TWILLIO_SENDING_NUMBER'] |= '+15555555555'
  ENV['TWILLIO_API_ACCOUNT'] |= 'test_api_account'
  ENV['TWILLIO_API_KEY'] |= 'test_api_key'

  # Ensure plain text credentials do not show up during logging
  c.filter_sensitive_data('<TWILLIO_STUDIO_FLOW>') { ENV['TWILLIO_STUDIO_FLOW'] }
  c.filter_sensitive_data('<TWILLIO_MESSAGING_SERVICE_SID>') { ENV['TWILLIO_MESSAGING_SERVICE_SID'] }
  c.filter_sensitive_data('<TWILLIO_SENDING_NUMBER>') { ENV['TWILLIO_SENDING_NUMBER'] }
  c.filter_sensitive_data('<TWILLIO_API_ACCOUNT>') { ENV['TWILLIO_API_ACCOUNT'] }
  c.filter_sensitive_data('<TWILLIO_API_KEY>') { ENV['TWILLIO_API_KEY'] }
  c.default_cassette_options = { record: :once }
end
