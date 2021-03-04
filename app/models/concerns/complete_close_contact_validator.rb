# frozen_string_literal: true

# Validates that at least one of several attributes is present
class CompleteCloseContactValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:base, "At least one of 'First Name' or 'Last Name' must be specified") if record.first_name.blank? && record.last_name.blank?
    record.errors.add(:base, "At least one of 'Primary Telephone' or 'Email' must be specified") if record.primary_telephone.blank? && record.email.blank?
  end
end
