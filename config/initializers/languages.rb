# Regenerate the data structure in language_constants.rb when languages change.
LANGUAGES = YAML.safe_load(File.read('lib/assets/languages.yml'), [Symbol]).freeze
VALID_LANGUAGES = LANGUAGES.stringify_keys.keys.freeze
DISPLAY_LANGUAGES = LANGUAGES.stringify_keys.transform_values { |v| v[:display]&.downcase }.invert.freeze
# Remove some languages that do not have ISO-639-1 codes.
ISO_6391_CODES = LANGUAGES.stringify_keys.transform_values { |v| v[:iso6391code]&.downcase }.invert.reject!{ |k, v| k.nil? }.freeze
