# frozen_string_literal: true

# Helper methods for languages
module Languages
  def self.supported_language?(lang)
    return false if lang.nil?

    # If the supported field exists at all for a language, then
    # that language can be considered supported
    all_languages&.dig(lang.to_sym, :supported)
  end

  # Even though some languages may be supported, we are unable to send
  # voice-calls in that language (typically due to Twilio limitations)
  def self.voice_unsupported?(lang)
    return false if lang.nil?

    !all_languages&.dig(lang.to_sym, :supported, :phone)
  end

  def self.all_languages
    PATIENT_HELPER_FILES[:languages]
  end

  def self.attempt_language_matching(lang)
    # This function returns the `lang` passed in if it can't be matched
    # Else returns the matched 'lang' iso code (stringified)
    matched_val = normalize_and_get_language_name(lang)
    matched_val ? matched_val.to_s : lang
  end

  # This function will attempt to match the input to a language in the system
  # PARAM: `lang` can be a three-letter iso-639-2t code, a two-letter iso-639-1 code, or the name (not case sensitive)
  # PARAM EXAMPLES: 'eng', 'en', 'English', 'ENGLISH' <-- All will map to 'eng'
  # RETURN VALUE: `nil` if unmatchable, else the three-letter iso code ('eng')
  def self.normalize_and_get_language_name(lang)
    return nil if lang.nil?

    lang = lang.to_s.downcase.strip
    matched_language = nil
    matched_language = lang.to_sym if all_languages[lang.to_sym].present?
    return matched_language unless matched_language.nil?

    matched_language = all_languages.find { |_key, val| val[:display]&.casecmp(lang)&.zero? }
    # [:fra, {:display=>"French", :iso6391code=>"fr", :system=>"iso639-2t" }]
    # matched_language will take the form of the above, and we want to return the 3-letter code at [0]
    return matched_language[0] unless matched_language.nil?

    matched_language = all_languages.find { |_key, val| val[:iso6391code]&.casecmp(lang)&.zero? }
    return matched_language[0] unless matched_language.nil?

    matched_language
  end
end
