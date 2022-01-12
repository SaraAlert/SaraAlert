# frozen_string_literal: true

# Contains all user account lock reasons
module LockReasons
  NO_LONGER_AN_EMPLOYEE = 'No longer an employee'
  NO_LONGER_NEEDS_ACCESS = 'No longer needs access'
  OTHER = 'Other'
  AUTO_LOCKED_BY_SYSTEM = 'Auto-locked by the System'

  def self.all_reasons
    constants.map { |c| const_get(c) }
  end

  # Lock reason value that admin users can manually assign
  def self.manual_lock_reasons
    constants.filter_map { |c| const_get(c) if c != :AUTO_LOCKED_BY_SYSTEM }
  end
end
