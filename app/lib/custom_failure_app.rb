# frozen_string_literal: true

class CustomFailureApp < Devise::FailureApp
  def respond
    byebug
    request.format.json? ? api_response : super
  end

  private

  def api_response
    byebug
    self.status = 401
    self.content_type = 'application/json'
    # optional - send a message in the response body
    # response.body = { error: i18n_message }.to_json
  end
end
