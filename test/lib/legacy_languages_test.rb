# frozen_string_literal: true

require 'test_case'

class LegacyLanguagesTest < ActiveSupport::TestCase
  include LegacyLanguages

  test 'translate_legacy_language_code' do
    assert_equal('eng', LegacyLanguages.translate_legacy_language_code('en'))
    assert_equal('spa-pr', LegacyLanguages.translate_legacy_language_code('es-PR'))
    assert_nil(LegacyLanguages.translate_legacy_language_code('es_PR'))
  end
end
