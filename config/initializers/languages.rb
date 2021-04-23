# Regenerate the data structure in language_constants.rb when languages change.
LANGUAGES = YAML.safe_load(File.read('lib/assets/languages.yml'), [Symbol]).freeze
