# frozen_string_literal: true

# Validates that a given date (attribute) is valid
class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # If value is unsuccessfully typecast to a date, it will be nil, so validate on the value before cast
    value ||= record.public_send("#{attribute}_before_type_cast")
    return if value.blank? || value.instance_of?(Date)

    unless value.match(/\d{4}-\d{2}-\d{2}/)
      err_msg = 'is not a valid date'
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
