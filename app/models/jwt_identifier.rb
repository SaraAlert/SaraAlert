# frozen_string_literal: true

# Laboratory: represents a lab result
class JwtIdentifier < ApplicationRecord
  belongs_to :application, class_name: 'OauthApplication'

  # Finds all of the JWT identifiers that belong to JWTs that have since expired
  # and therefore no longer need to be checked.
  scope :purge_eligible, lambda {
    where('expiration_date <= ?', Time.now)
  }
end
