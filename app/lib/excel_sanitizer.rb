# frozen_string_literal: true

# String manipulation of data fields that are to be exported
# Not intended to protect against any threat vector through Excel
# Intent is to reduce errors when viewing exported files
module ExcelSanitizer
  # Removes = from the beginning of a string to avoid "#NAME!" and
  # "There is a problem with a formula in this file" errors
  def remove_formula_start(string)
    return string unless string&.starts_with?('=') || string&.starts_with?(' ==')

    remove_formula_start(string[1..])
  end
end
