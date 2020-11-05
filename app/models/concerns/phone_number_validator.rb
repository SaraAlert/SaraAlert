# frozen_string_literal: true

# Validates that a given phone number (attribute) is valid
class PhoneNumberValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    phone = Phonelib.parse(value, 'US')
    return unless phone.national(false).nil? || phone.national(false).length != 10

    record.errors.add(attribute, 'is not a valid phone number')
  end
end
