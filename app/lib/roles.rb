# frozen_string_literal: true

# Contains valid Role attribute in the User model and methods to work with them
module Roles
  SUPER_USER = 'super_user'
  PUBLIC_HEALTH_ENROLLER = 'public_health_enroller'
  CONTACT_TRACER = 'contact_tracer'
  PUBLIC_HEALTH = 'public_health'
  ENROLLER = 'enroller'
  ANALYST = 'analyst'
  ADMIN = 'admin'
  NONE = 'none'

  def self.all_role_values
    constants.map { |c| const_get(c) }
  end

  # Role values that users can be assigned to
  def self.all_assignable_role_values
    constants.map { |c| const_get(c) if c != :NONE }.compact
  end
end
