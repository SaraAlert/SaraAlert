# frozen_string_literal: true

# Top level class for handling application errors allows us to render error
# pages which match the rest of the application's style
class ErrorsController < ApplicationController
  def not_found
    render status: 404
  end

  def unprocessable
    render status: 422
  end

  def internal_server_error
    render status: 500
  end
end
