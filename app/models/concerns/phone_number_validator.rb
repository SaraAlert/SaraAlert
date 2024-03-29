# frozen_string_literal: true

# Validates that a given phone number (attribute) is valid
class PhoneNumberValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    phone = Phonelib.parse(value, 'US')
    return unless phone.full_e164.blank? || phone.full_e164.sub(/^\+1+/, '').length != 10

    record.errors.add(attribute, 'is not a valid phone number')
  end
end
