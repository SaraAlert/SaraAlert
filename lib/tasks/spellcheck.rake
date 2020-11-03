# frozen_string_literal: true

if Rails.env.test?
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
  def check_locale(filepath)
    num_errors = 0
    locale_hash = recursive_parsing(YAML.load_file(filepath))

    FFI::Hunspell.dict('en_US') do |dict|
      customize_en_us_dictionary(dict)
      locale_hash.each do |key, sentence|
        # Ignore any variables for spell checking
        sentence.gsub!(/%{\w+}/, '')
        # Track if we already printed the YAML path and the sentence.
        already_put_context = false
        words = sentence.scan(/[\w'-]+/)
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
  # right now this is just for the en_US dictionary, but in the future may
  # spellcheck other languages as well.
  def customize_en_us_dictionary(dict)
    dict.add('admin')
    dict.add('admin_authenticator')
    dict.add('apps')
    dict.add('Authy')
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
  end


  # Main method for the script.
  # Each command line argument is treated as a file path or potential glob
  # and spell checking is run on all files provided.
  # Exits with code 0 if no spelling errors are found.
  # Exits with code 1 if one or more spelling errors are found.
  def main
    num_errors = 0
    locale_globs = [
      'config/locales/*.en.yml',
      'config/locales/en.yml'
    ]
    locale_globs.each do |glob|
      Dir.glob(glob).each do|filepath|
        puts "CHECKING LOCALE: #{filepath}"
        num_errors += check_locale(filepath)
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
