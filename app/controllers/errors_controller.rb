# frozen_string_literal: true

# Top level class for handling application errors allows us to render error
# pages which match the rest of the application's style
class ErrorsController < ApplicationController
  def not_found
    render status: :not_found
  end

  def unprocessable
    render status: :unprocessable_entity
  end

  def internal_server_error
    render status: :internal_server_error
  end
end
