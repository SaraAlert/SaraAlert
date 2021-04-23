# Regenerate the data structure in language_constants.rb when languages change.
LANGUAGES = YAML.safe_load(File.read('lib/assets/languages.yml'), [Symbol]).freeze
VALID_LANGUAGES = LANGUAGES.stringify_keys.keys.freeze
SORTED_DISPLAY_LANGUAGES = []
LANGUAGES.each { |lang| SORTED_DISPLAY_LANGUAGES << lang[1][:display].downcase }.freeze
LANGUAGES_AS_ARRAY = LANGUAGES.to_a.freeze
