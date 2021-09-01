# frozen_string_literal: true

require 'test_case'

class LanguagesTest < ActiveSupport::TestCase
  include Languages

  test 'supported_language' do
    assert(Languages.supported_language?('eng'))
    assert_not(Languages.supported_language?('test'))
  end

  test 'all_languages' do
    assert_equal(LANGUAGES, Languages.all_languages)
  end

  # variants of arguments are tested in the called method
  # normalize_and_get_language_code
  test 'attempt_language_matching' do
    # Exists French => fra
    assert_equal('fra', Languages.attempt_language_matching('French'))
    # Does not exist arg => arg
    assert_equal('Ruby Language', Languages.attempt_language_matching('Ruby Language'))
  end

  test 'normalize_and_get_language_code non-string' do
    assert_nil(Languages.normalize_and_get_language_code(:en))
  end

  test 'translate code to display string' do
    assert_equal(Languages.translate_code_to_display('eng'), 'English')
    assert_equal(Languages.translate_code_to_display('fra'), 'French')
    assert_equal(Languages.translate_code_to_display('isl'), 'Icelandic')

    assert_equal(Languages.translate_code_to_display(:ita), 'Italian')
    assert_equal(Languages.translate_code_to_display(:cha), 'Chamorro')
    assert_equal(Languages.translate_code_to_display(:ase), 'American Sign Language')

    assert_nil(Languages.translate_code_to_display('INVALID LANGUAGE'))
    assert_nil(Languages.translate_code_to_display(nil))
  end

  test 'normalize_and_get_language_code 2-letter-code' do
    assert_equal(:eng, Languages.normalize_and_get_language_code('en'))
    assert_equal(:'spa-pr', Languages.normalize_and_get_language_code('es-PR'))
  end

  test 'normalize_and_get_langauge_name display' do
    assert_equal(:eng, Languages.normalize_and_get_language_code('English'))
    assert_equal(:'spa-pr', Languages.normalize_and_get_language_code('Spanish (Puerto Rican)'))
    assert_equal(:spa, Languages.normalize_and_get_language_code('Spanish'))
  end

  test 'normalize_and_get_langauge_name 3-letter-code' do
    assert_equal(:eng, Languages.normalize_and_get_language_code('eng'))
    assert_equal(:'spa-pr', Languages.normalize_and_get_language_code('spa-pr'))
    assert_equal(:spa, Languages.normalize_and_get_language_code('spa'))
  end
end
