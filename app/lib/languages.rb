# frozen_string_literal: true

# Helper methods for languages
module Languages
  def self.supported_language?(lang, medium = nil)
    return false if lang.nil?

    # If the supported field exists at all for a language, then
    # that language can be considered supported
    medium.present? ? all_languages&.dig(lang.to_sym, :supported, medium) : all_languages&.dig(lang.to_sym, :supported) || false
  end

  def self.all_languages
    LANGUAGES
  end

  def self.attempt_language_matching(lang)
    # This function returns the `lang` passed in if it can't be matched
    # Else returns the matched 'lang' iso code (stringified)
    matched_val = normalize_and_get_language_code(lang)
    matched_val ? matched_val.to_s : lang
  end

  # Given an 3-letter iso code, return the Language Display name for that language
  # Function will return nil for nil (or unmatchable)
  # PARAM: 'eng', 'spa', 'fra'
  # RETURN VALUE: 'English', 'Spanish', 'French'
  def self.translate_code_to_display(lang)
    Languages.all_languages.dig(lang&.to_sym, :display)
  end

  # This function will attempt to match the input to a language in the system
  # PARAM: `lang` can be a three-letter iso-639-2t code, a two-letter iso-639-1 code, or the name (not case sensitive)
  # PARAM EXAMPLES: 'eng', 'en', 'English', 'ENGLISH' <-- All will map to 'eng'
  # RETURN VALUE: `nil` if unmatchable, else the three-letter iso code ('eng')
  def self.normalize_and_get_language_code(lang)
    return nil if lang.nil? || !lang.is_a?(String)

    lang = lang.downcase.strip
    return lang.to_sym if all_languages.key?(lang.to_sym)

    DISPLAY_LANGUAGES[lang]&.to_sym || ISO_6391_CODES[lang]&.to_sym
  end
end
