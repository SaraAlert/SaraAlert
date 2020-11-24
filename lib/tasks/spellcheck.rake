# frozen_string_literal: true

# Hunspell GitHub: https://github.com/hunspell/hunspell
# ffi-hunspell Ruby Gem GitHub: https://github.com/postmodern/ffi-hunspell
# ffi-hunspell Ruby Gem Docs: https://rubydoc.info/gems/ffi-hunspell/frames
# Hunspell Dictionary Source: https://cgit.freedesktop.org/libreoffice/dictionaries/tree/


if Rails.env.test? || Rails.env.development?
  require 'yaml'
  require 'ffi/hunspell' # inject Hunspell class to Ruby namespace

  # Flatten the map while preserviing the paths to the the leaf values for
  # ease of locating errors to be fixed
  #
  # Source:
  # https://stackoverflow.com/questions/48836464/how-to-flatten-a-hash-making-each-key-a-unique-value
  def recursive_parsing(object, tmp = [])
    case object
    when Array
      object.each.with_index(1).with_object({}) do |(element, i), result|
        result.merge! recursive_parsing(element, tmp + [i])
      end
    when Hash
      object.each_with_object({}) do |(key, value), result|
        result.merge! recursive_parsing(value, tmp + [key])
      end
    else
      { tmp.join(' => ') => object }
    end
  end


  # Check each of the words provided to check if it is spelled correctly
  # for the hunspell checker (using the en_US dictionary).
  #
  # returns a boolean indicating if any words were found to be mispelled
  def check_locale(dict_name, filepath)
    num_errors = 0
    locale_hash = recursive_parsing(YAML.load_file(filepath))

    FFI::Hunspell.dict(dict_name) do |dict|
      customize_dictionary(dict_name, dict)
      locale_hash.each do |key, sentence|
        # Ignore any variables for spell checking.
        sentence.gsub!(/%{\w+}/, '')
        # Ignore the expected temperature guidance.
        sentence.gsub!('100.4°F/38°C', '')
        # Track if we already printed the YAML path and the sentence.
        already_put_context = false
        words = sentence.scan(/[[:alpha:]\w'-]+/)
        words.each do |word|
          # Safety check if word is not actually a String.
          next if !word.is_a? String
          # dict.check? returns true if correctly spelled and false if incorrect.
          next if dict.check?(word)
          # Detected an error, so print the error and suggested fixes.
          if !already_put_context
            puts "\n\t#{key}"
            puts "\t#{sentence}"
            already_put_context = true
          end
          puts "\t\tSPELLING ERROR: #{word}"
          puts "\t\t\tSUGGESTIONS: #{dict.suggest(word)}"
          num_errors += 1
        end
      end
    end
    puts "\n\tFound #{num_errors} errors when checking locale file #{filepath}"
    num_errors
  end

  # Add in custom words that do not already exist in the Hunspell dictionary
  def customize_dictionary(dict_name, dict)
    customize_en_us_dictionary(dict) if dict_name == :en_US
    customize_es_pr_dictionary(dict) if dict_name == :es_PR
    customize_fr_dictionary(dict) if dict_name == :fr_FR
  end


  # Customize the es_PR dictionary
  def customize_es_pr_dictionary(dict)
    dict.add('Sara')
    dict.add('Alert')
    dict.add('Fahrenheit')
    dict.add('infórmeles')
    dict.add('intentemoslo')
    dict.add('oxímetro')
    dict.add('recordándole')
    dict.add('saraalert')
    dict.add('org')
  end


  # Customize the fr dictionary
  def customize_fr_dictionary(dict)
    dict.add('Sara')
    dict.add('Alert')
    dict.add('Other')
    dict.add('saraalert')
    dict.add('org')
  end


  # Customize the en_US dictionary
  def customize_en_us_dictionary(dict)
    dict.add('admin')
    dict.add('admin_authenticator')
    dict.add('apps')
    dict.add('Authy')
    dict.add('cancelled')
    dict.add('captcha')
    dict.add('code_verifier')
    dict.add('HTTPS')
    dict.add('OAuth')
    dict.add('OAuth2')
    dict.add('pkce')
    dict.add('pre-authorization')
    dict.add('resource_owner_authenticator')
    dict.add('resource_owner_from_credentials')
    dict.add('S256')
    dict.add('SMS')
    dict.add('SSL')
    dict.add('UID')
    dict.add('unconfigured')
    dict.add('uri')
    dict.add('urls')
    dict.add('webpage')
    dict.add('saraalert')
    dict.add('org')
  end


  # Main method for the script.
  # Each command line argument is treated as a file path or potential glob
  # and spell checking is run on all files provided.
  # Exits with code 0 if no spelling errors are found.
  # Exits with code 1 if one or more spelling errors are found.
  def main
    num_errors = 0
    # { <dictionary filename>: [<glob>, ..., <glob>], ... }
    locale_globs = {
      'en_US': [
        'config/locales/*.en.yml',
        'config/locales/en.yml'
      ],
      'es_PR': [
        'config/locales/es-PR.yml',
        'config/locales/es.yml'
      ],
      'fr_FR': [
        'config/locales/fr.yml'
      ]
    }
    locale_globs.each do |dict_name, glob|
      Dir.glob(glob).each do|filepath|
        puts "CHECKING LOCALE: #{filepath} with dictionary #{dict_name}"
        num_errors += check_locale(dict_name, filepath)
        puts "\n\n"
      end
    end
    puts "Found #{num_errors} errors when checking all locale files"
    exit(1) if num_errors > 0
  end

  task spellcheck: :environment do
    main
  end
end
