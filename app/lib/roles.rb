# frozen_string_literal: true

# Contains valid Role attribute in the User model and methods to work with them
module Roles
  ADMIN = 'admin'
  ANALYST = 'analyst'
  ENROLLER = 'enroller'
  NONE = 'none'
  PUBLIC_HEALTH = 'public_health'
  PUBLIC_HEALTH_ENROLLER = 'public_health_enroller'

  def self.all_role_values
    constants.map { |c| const_get(c) }
  end

  # Role values that users can be assigned to
  def self.all_assignable_role_values
    constants.map { |c| const_get(c) if c != :NONE }.compact
  end
end
