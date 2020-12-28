# frozen_string_literal: true

# TokensController: add logging to TokensController defined by Doorkeeper
class TokensController < Doorkeeper::TokensController
  after_action do
    Rails.logger.info("Response: #{response.body}") if response.status >= 400 && !response.body.blank?
  end
end
