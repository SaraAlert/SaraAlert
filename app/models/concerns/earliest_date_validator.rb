# frozen_string_literal: true

class EarliestDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless options.key?(:date)

    raise TypeError, "#{options[:date]} does not implement required comparison methods" unless options[:date].acts_like?(:date)

    record.errors.add(attribute, "cannot occur before #{options[:date]}") unless valid?(value, options[:date])
  end

  private

  def  valid?(value, provided)
    if value.nil?
      true
    elsif !value.acts_like?(:date)
      false
    else
      value >= provided
    end
  end
end
