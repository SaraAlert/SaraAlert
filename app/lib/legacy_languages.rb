# frozen_string_literal: true

# For backwards-compatibility reasons, we still want to support the old 2-letter language codes
# This module provides a home for any legacy language functionality
module LegacyLanguages
  LEGACY_LANGUAGE_MAPPING = {
    'en' => 'eng',
    'es' => 'spa',
    'es-PR' => 'spa-pr',
    'so' => 'som',
    'fr' => 'fra'
  }.freeze

  # Given a two-letter code, returns a three-letter code above or nil
  def self.translate_legacy_language_code(lang)
    LEGACY_LANGUAGE_MAPPING[lang]
  end
end
