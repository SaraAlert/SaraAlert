# frozen_string_literal: true

# ApplicationAPIController: defines methods useful for all API controllers
class ApplicationApiController < ActionController::API
  include ActionController::MimeResponds

  PATIENT_READ_SCOPES = %i[user/Patient.read user/Patient.* system/Patient.read system/Patient.*].freeze
  PATIENT_WRITE_SCOPES = %i[user/Patient.write user/Patient.* system/Patient.write system/Patient.*].freeze
  RELATED_PERSON_READ_SCOPES = %i[user/RelatedPerson.read user/RelatedPerson.* system/RelatedPerson.read system/RelatedPerson.*].freeze
  RELATED_PERSON_WRITE_SCOPES = %i[user/RelatedPerson.write user/RelatedPerson.* system/RelatedPerson.write system/RelatedPerson.*].freeze
  IMMUNIZATION_READ_SCOPES = %i[user/Immunization.read user/Immunization.* system/Immunization.read system/Immunization.*].freeze
  IMMUNIZATION_WRITE_SCOPES = %i[user/Immunization.write user/Immunization.* system/Immunization.write system/Immunization.*].freeze
  OBSERVATION_READ_SCOPES = %i[user/Observation.read user/Observation.* system/Observation.read system/Observation.*].freeze
  OBSERVATION_WRITE_SCOPES = %i[user/Observation.write user/Observation.* system/Observation.write system/Observation.*].freeze
  QUESTIONNAIRE_RESPONSE_READ_SCOPES = %i[user/QuestionnaireResponse.read system/QuestionnaireResponse.read].freeze
  PROVENANCE_READ_SCOPES = %i[user/Provenance.read system/Provenance.read].freeze

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

  # Generic 202 accepted response
  def status_accepted
    respond_to do |format|
      format.any { head :accepted }
    end
  end

  class ClientError < StandardError; end
end
