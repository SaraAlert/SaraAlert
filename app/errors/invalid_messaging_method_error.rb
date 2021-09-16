# frozen_string_literal: true

class InvalidMessagingMethodError < StandardError
  def initialize(klass, method)
    super("#{klass}##{method} is not a valid message method")
  end
end
