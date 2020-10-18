# frozen_string_literal: true

# Validates that a given phone number (attribute) is valid
class EmailValidator < ActiveModel::EachValidator
  include ValidationHelper
  def validate_each(record, attribute, value)
    return nil if value.blank?
    unless ValidEmail2::Address.new(value).valid?
      record.errors.add(attribute, "'#{value}' is not a valid Email Address for '#{VALIDATION[attribute][:label]}'")
    end
  end
end