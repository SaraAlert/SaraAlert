# frozen_string_literal: true

# Validates that either an address_state or a foreign_address_country is present
class RequiredAddressValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:base, "One of 'State' or 'Foreign Address Country' is required") if record.address_state.blank? && record.foreign_address_country.blank?
  end
end
