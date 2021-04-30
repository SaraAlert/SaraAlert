# frozen_string_literal: true

# ApplicationAPIController: defines methods useful for all API controllers
class ApplicationApiController < ActionController::API
  include ActionController::MimeResponds
  # Generic 401 unauthorized
  def status_unauthorized
    respond_to do |format|
      format.any { head :unauthorized }
    end
  end

  # Generic 406 not acceptable
  def status_not_acceptable
    respond_to do |format|
      format.any { head :not_acceptable }
    end
  end

  # Generic 415 unsupported media type
  def status_unsupported_media_type
    respond_to do |format|
      format.any { head :unsupported_media_type }
    end
  end

  # Generic 403 forbidden response
  def status_forbidden
    respond_to do |format|
      format.any { head :forbidden }
    end
  end

  # Generic 404 not found response
  def status_not_found
    respond_to do |format|
      format.any { head :not_found }
    end
  end
end
