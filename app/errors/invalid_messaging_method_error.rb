# frozen_string_literal: true

# Raised when an invalid method is passed to the message sender (i.e. TwilioSender)
class InvalidMessagingMethodError < StandardError
  def initialize(klass, method)
    super("#{klass}##{method} is not a valid message method")
  end
end
