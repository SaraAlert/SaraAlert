# frozen_string_literal: true

# Validates that a given date (attribute) is valid
class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    err_msg = 'is not a valid date'

    # If we can, validate using the pre-type cast value, since this will more accurately reflect user input
    value = record.public_send("#{attribute}_before_type_cast") || value
    if value.is_a? Numeric
      record.errors.add(attribute, "#{err_msg}, please use the 'YYYY-MM-DD' format")
      return
    end

    return if value.blank? || !value.respond_to?(:match)

    unless value.match(/\d{4}-\d{2}-\d{2}/)
      if value.match(%r{\d{2}/\d{2}/\d{4}})
        record.errors.add(attribute, "#{err_msg} due to ambiguity between 'MM/DD/YYYY' and 'DD/MM/YYYY', please use the 'YYYY-MM-DD' format instead")
      else
        record.errors.add(attribute, "#{err_msg}, please use the 'YYYY-MM-DD' format")
      end
      return
    end

    begin
      Date.parse(value)
    rescue ArgumentError
      record.errors.add(attribute, 'is not a valid date')
    end
  end
end
