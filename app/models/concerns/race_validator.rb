# frozen_string_literal: true

# Validates that a given date (attribute) is valid
class RaceValidator < ActiveModel::Validator
  def validate(record)
    has_non_exclusive_race = record.white || record.black_or_african_american || record.american_indian_or_alaska_native ||
                             record.asian || record.native_hawaiian_or_other_pacific_islander || record.race_other

    return unless has_non_exclusive_race ? (record.race_unknown || record.race_refused_to_answer) : (record.race_unknown && record.race_refused_to_answer)

    record.errors.add(record.race_unknown ? :race_unknown : :race_refused_to_answer, 'cannot be true if any other race parameters are also true')
  end
end
