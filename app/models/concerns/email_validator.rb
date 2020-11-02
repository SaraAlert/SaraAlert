# frozen_string_literal: true

# Validates that a given email (attribute) is valid
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    return if ValidEmail2::Address.new(value).valid?

    record.errors.add(attribute, 'is not a valid Email Address')
  end
end
