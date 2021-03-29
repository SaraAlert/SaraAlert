# frozen_string_literal: true

# rubocop:disable Metrics/BlockNesting
# rubocop:disable Style/MutableConstant

SCRIPT_MODE = 'DRY_RUN' # ["DRY_RUN", "LIVE"]

EXPOSURE_NOTES_FIELD_MAX_LENGTH = 2000

CUSTOM_TRANSLATIONS = {
  'bilingual english/spanish': 'english',
  'portugese': 'portuguese',
  'bos': 'bosnian',
  'laotian': 'lao',
  'pelugu': 'telugu',
  'telegu': 'telugu',
  'philippines': 'filipino',
  'punjabi': 'panjabi',
  'frysian': 'frisian',
  'haitian creole': 'haitian'
  # 'cantonese': 'chinese', # See http://www.loc.gov/standards/iso639-2/faq.html#24
  # 'mandarin': 'chinese' # See http://www.loc.gov/standards/iso639-2/faq.html#24
}
LANGUAGES = YAML.safe_load(File.read('lib/assets/languages.yml'), [Symbol])
UNMATCHABLE_LANGUAGES = []
# Create lookup table where the language name is the key for fast translations
INVERTED_ISO_LOOKUP = {}
LANGUAGES.each_key do |lang_iso_code|
  INVERTED_ISO_LOOKUP[LANGUAGES[lang_iso_code.to_sym][:display].to_s.downcase] = lang_iso_code
end

def match_language(lang)
  return nil if lang.nil?

  # tries to match lang to either a 3-letter iso code or a language name
  # If able to match, returns the 3-letter iso code for that language
  # If unable to match, returns nil

  # first search in all 3-letter language codes
  matched_language = nil
  # then search by language display name
  matched_language = LANGUAGES[lang.to_sym][:code] if LANGUAGES[lang.to_sym]
  return matched_language unless matched_language.nil?

  matched_language = INVERTED_ISO_LOOKUP[lang] unless INVERTED_ISO_LOOKUP[lang].nil?
  matched_language
end

def get_long_notes_text(new_iso_code, old_language)
  todays_date = Time.now.strftime('%m/%d/%Y')
  new_language = LANGUAGES[new_iso_code.to_sym][:display] unless new_iso_code.nil?
  "System note (#{todays_date}): Primary language was listed as '#{old_language}' \
which could not be matched to the standard language list. This monitoree’s primary \
language has been updated to '#{new_language.nil? ? 'blank' : new_language}'. You \
may update this value." # This terminology comes from the PO Team
end

def get_short_notes_text(new_iso_code, old_language)
  # If there is not room for the text from get_long_notes_text(), use this
  todays_date = Time.now.strftime('%m/%d/%Y')
  new_language = LANGUAGES[new_iso_code.to_sym][:display] unless new_iso_code.nil?
  "System note (#{todays_date}): Primary language changed from '#{old_language}' \
to '#{new_language.nil? ? 'blank' : new_language}}.'"
end

def get_all_unmamtchable_count(lang)
  count = 0
  Patient.where.not("#{lang}": nil).find_each do |monitoree|
    matched_lang = match_language(monitoree[lang.to_sym].to_s.downcase)
    UNMATCHABLE_LANGUAGES.push(monitoree[lang.to_sym].to_s.downcase) if matched_lang.nil?
    count += matched_lang.nil? ? 1 : 0
  end
  count
end

if SCRIPT_MODE == 'DRY_RUN'

  total_patient_count = Patient.all.length
  total_primary_lang_count = Patient.where.not(primary_language: nil).length
  unmatchable_primary_langs = get_all_unmamtchable_count('primary_language')
  matchable_primary_langs = total_primary_lang_count - unmatchable_primary_langs

  total_secondary_lang_count = Patient.where.not(secondary_language: nil).length

  unmatchable_secondary_langs = get_all_unmamtchable_count('secondary_language')

  matchable_secondary_langs = total_secondary_lang_count - unmatchable_secondary_langs
  printf("\n\nRunning in DRY RUN mode (No live data changes)\n")
  printf("Total Monitorees: #{total_patient_count}\n")
  printf("Total Monitorees w/ Primary Language: #{total_primary_lang_count}\n")
  primary_fraction_match = format('%.2f', (matchable_primary_langs.to_f / total_primary_lang_count * 100))
  printf("Matchable Primary Languages = #{matchable_primary_langs}/#{total_primary_lang_count} (#{primary_fraction_match}%%)\n")
  format('%.2f', primary_fraction_unmatch = (unmatchable_primary_langs.to_f / total_primary_lang_count * 100))
  printf("Unmatchable Primary Languages = #{unmatchable_primary_langs}/#{total_primary_lang_count} (#{primary_fraction_unmatch}%%)\n")
  printf("\n")
  printf("Total Monitorees w/ Secondary Language: #{total_secondary_lang_count}\n")
  format('%.2f', secondary_fraction_match = (matchable_secondary_langs.to_f / total_secondary_lang_count * 100))
  printf("Matchable Secondary Languages = #{matchable_secondary_langs}/#{total_secondary_lang_count} (#{secondary_fraction_match}%%)\n")
  format('%.2f', secondary_fraction_unmatch = (unmatchable_secondary_langs.to_f / total_secondary_lang_count * 100))
  printf("Unmatchable Secondary Languages = #{unmatchable_secondary_langs}/#{total_secondary_lang_count} (#{secondary_fraction_unmatch}%%)\n")
  printf("\nThe unmatchable languages are:\n#{UNMATCHABLE_LANGUAGES.uniq}\n")
  printf("\n")
  printf('Press anything to begin...')
  gets

  Patient.find_each do |monitoree|
    unless monitoree[:primary_language].nil? # guarantees going forward that the primary_language exists
      currrent_language = monitoree[:primary_language].to_s.downcase
      if CUSTOM_TRANSLATIONS.keys.include?(currrent_language.to_sym)
        monitoree[:secondary_language] = 'spanish' if currrent_language == 'bilingual english/spanish'
        lang_iso_code = INVERTED_ISO_LOOKUP[CUSTOM_TRANSLATIONS[currrent_language.to_sym]]
        exposure_notes_language_long = get_long_notes_text(lang_iso_code, currrent_language)
        exposure_notes_language_short = get_short_notes_text(lang_iso_code, currrent_language)
        language_text = ''
        current_exposure_notes_length = monitoree[:exposure_notes] ? monitoree[:exposure_notes].length : 0
        if EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_long.length
          language_text = exposure_notes_language_long
        elsif EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_short.length
          language_text = exposure_notes_language_short
        end
        monitoree[:exposure_notes] = monitoree[:exposure_notes] ? monitoree[:exposure_notes] << language_text : language_text unless language_text.nil?
        monitoree[:primary_language] = lang_iso_code
      else
        lang_iso_code = match_language(currrent_language)
        if lang_iso_code.nil?
          unmatchable_lang = currrent_language
          while lang_iso_code.nil?
            printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
            printf("Unable to match language '#{unmatchable_lang}' for Patient ID #{monitoree[:id]}\n")
            printf("Type a 3-letter iso-code or a language name to assign this monitoree.\n('nil' is an acceptable entry)\n")
            printf("The system will confirm your input before continuing further.\n")
            printf('Enter Languge: ')
            unmatchable_lang = gets.chomp
            lang_iso_code = unmatchable_lang == 'nil' ? 'nil' : match_language(unmatchable_lang.to_s.downcase) # use the string nil to break out of the `while`
          end
          lang_iso_code = lang_iso_code == 'nil' ? nil : lang_iso_code
          total_patients_with_lang = Patient.where('lower(primary_language) = ?', monitoree[:primary_language]).length
          printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
          if lang_iso_code
            printf("The System was successfully able to match '#{unmatchable_lang}' to '#{LANGUAGES[lang_iso_code.to_sym]}'.\n")
          else
            printf("The System successfully registed your 'nil' entry.")
          end
          if total_patients_with_lang > 1
            printf("\nThere are #{total_patients_with_lang - 1} other Patient#{if (total_patients_with_lang - 1) > 1
                                                                                 's'
                                                                               end} with the language '#{currrent_language}' as their primary language.\n")
            printf("Enter '1' if you would like to change them all to '#{lang_iso_code || 'nil'}'\n")
            printf("Enter '2' if you would like to ONLY change this Monitoree to '#{lang_iso_code || 'nil'}'\n")
            printf("The System will ask what you want to do with the old language next.\n")
            printf("Please note if select Option 1, the System will attempt to include the previous language in the exposure notes for all future monitorees with this language.\n")
            printf('Your Input (1 or 2): ')
            user_input = gets.chomp
            if user_input.to_s == '1'
              CUSTOM_TRANSLATIONS[currrent_language.to_sym] = lang_iso_code
              printf("Successfully added a mapping from '#{currrent_language}' to '#{lang_iso_code || 'nil'}'\n")
            end
            if user_input.to_s == '2'
              # do nothing
            end
          end
          printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
          printf("The System now needs to decide what to do with the old language code.\n")
          printf("Please note the exact phrasing will be:\n")
          exposure_notes_language_long = get_long_notes_text(lang_iso_code, currrent_language)
          exposure_notes_language_short = get_short_notes_text(lang_iso_code, currrent_language)
          printf("If there is more than #{exposure_notes_language_long.length} characters free, the following will be appended to any Notes:\n")
          printf("\t#{exposure_notes_language_long}\n")
          printf("\nIf there is more than #{exposure_notes_language_short.length} characters free, the following will be appended to any Notes:\n")
          printf("\t#{exposure_notes_language_short}\n")
          printf("\nIf there are not #{exposure_notes_language_short.length} characters free, the Exposure Notes will not be updated and the data dropped.\n")
          printf("\nEnter '1' if you would like to attempt to include it in the 'Exposure Notes' field for this monitoree.\n")
          printf("Enter '2' if you would like to drop the data.\n")
          printf('Your Input (1 or 2): ')
          user_input = gets.chomp
          if user_input.to_s == '1'
            language_text = ''
            current_exposure_notes_length = monitoree[:exposure_notes] ? monitoree[:exposure_notes].length : 0
            if EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_long.length
              language_text = exposure_notes_language_long
            elsif EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_short.length
              language_text = exposure_notes_language_short
            end
            monitoree[:exposure_notes] = monitoree[:exposure_notes] ? monitoree[:exposure_notes] << language_text : language_text unless language_text.nil?
          end
          if user_input.to_s == '2'
            # do nothing
          end
        else
          monitoree[:primary_language] = lang_iso_code
          # monitoree.save!
        end
      end
    end
    unless monitoree[:secondary_language].nil? # guarantees going forward that the secondary_language exists
      currrent_language = monitoree[:secondary_language].to_s.downcase
      if CUSTOM_TRANSLATIONS.keys.include?(currrent_language.to_sym)
        lang_iso_code = INVERTED_ISO_LOOKUP[CUSTOM_TRANSLATIONS[currrent_language.to_sym]]
        exposure_notes_language_long = get_long_notes_text(lang_iso_code, currrent_language)
        exposure_notes_language_short = get_short_notes_text(lang_iso_code, currrent_language)
        monitoree[:secondary_language] = lang_iso_code
        language_text = ''
        current_exposure_notes_length = monitoree[:exposure_notes] ? monitoree[:exposure_notes].length : 0
        if EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_long.length
          language_text = exposure_notes_language_long
        elsif EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_short.length
          language_text = exposure_notes_language_short
        end
        monitoree[:exposure_notes] = monitoree[:exposure_notes] ? monitoree[:exposure_notes] << language_text : language_text unless language_text.nil?
      else
        lang_iso_code = match_language(currrent_language)
        if lang_iso_code.nil?
          unmatchable_lang = currrent_language
          while lang_iso_code.nil?
            printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
            printf("Unable to match language '#{unmatchable_lang}' for Patient ID #{monitoree[:id]}\n")
            printf("Type a 3-letter iso-code or a language name to assign this monitoree.\n('nil' is an acceptable entry)\n")
            printf("The system will confirm your input before continuing further.\n")
            printf('Enter Languge: ')
            unmatchable_lang = gets.chomp
            lang_iso_code = unmatchable_lang == 'nil' ? 'nil' : match_language(unmatchable_lang.to_s.downcase) # use the string nil to break out of the `while`
          end
          lang_iso_code = lang_iso_code == 'nil' ? nil : lang_iso_code
          total_patients_with_lang = Patient.where('lower(secondary_language) = ?', monitoree[:secondary_language]).length
          printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
          if lang_iso_code
            printf("The System was successfully able to match '#{unmatchable_lang}' to '#{LANGUAGES[lang_iso_code.to_sym]}'.\n")
          else
            printf("The System successfully registed your 'nil' entry.\n")
          end
          if total_patients_with_lang > 1
            printf("\nThere are #{total_patients_with_lang - 1} other Patient#{if (total_patients_with_lang - 1) > 1
                                                                                 's'
                                                                               end} with the language '#{currrent_language}' as their primary language.\n")
            printf("Enter '1' if you would like to change them all to '#{lang_iso_code || 'nil'}'\n")
            printf("Enter '2' if you would like to ONLY change this Monitoree to '#{lang_iso_code || 'nil'}'\n")
            printf("The System will ask what you want to do with the old language next.\n")
            printf("Please note if select Option 1, the System will attempt to include the previous language in the exposure notes for all future monitorees with this language.\n")
            printf('Your Input (1 or 2): ')
            user_input = gets.chomp
            if user_input.to_s == '1'
              CUSTOM_TRANSLATIONS[currrent_language.to_sym] = lang_iso_code
              printf("Successfully added a mapping from '#{currrent_language}' to '#{lang_iso_code || 'nil'}'\n")
            end
            if user_input.to_s == '2'
              # do nothing
            end
          end
          printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
          printf("The System now needs to decide what to do with the old language code.\n")
          printf("Please note the exact phrasing will be:\n")
          exposure_notes_language_long = get_long_notes_text(lang_iso_code, currrent_language)
          exposure_notes_language_short = get_short_notes_text(lang_iso_code, currrent_language)
          printf("If there is more than #{exposure_notes_language_long.length} characters free, the following will be appended to any Notes:\n")
          printf("\t#{exposure_notes_language_long}\n")
          printf("\nIf there is more than #{exposure_notes_language_short.length} characters free, the following will be appended to any Notes:\n")
          printf("\t#{exposure_notes_language_short}\n")
          printf("\nIf there are not #{exposure_notes_language_short.length} characters free, the Exposure Notes will not be updated and the data dropped.\n")
          printf("\nEnter '1' if you would like to attempt to include it in the 'Exposure Notes' field for this monitoree.\n")
          printf("Enter '2' if you would like to drop the data.\n")
          printf('Your Input (1 or 2): ')
          user_input = gets.chomp
          if user_input.to_s == '1'
            language_text = ''
            current_exposure_notes_length = monitoree[:exposure_notes] ? monitoree[:exposure_notes].length : 0
            if EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_long.length
              language_text = exposure_notes_language_long
            elsif EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_short.length
              language_text = exposure_notes_language_short
            end
            monitoree[:exposure_notes] = monitoree[:exposure_notes] ? monitoree[:exposure_notes] << language_text : language_text unless language_text.nil?
          end
          if user_input.to_s == '2'
            # do nothing
          end
        else
          monitoree[:secondary_language] = lang_iso_code
        end
      end
    end
  end
  printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
  printf("System completed all Language translations successfully!\n")
  printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n\n")
end

if SCRIPT_MODE == 'LIVE'

  total_patient_count = Patient.all.length
  total_primary_lang_count = Patient.where.not(primary_language: nil).length
  unmatchable_primary_langs = get_all_unmamtchable_count('primary_language')
  matchable_primary_langs = total_primary_lang_count - unmatchable_primary_langs

  total_secondary_lang_count = Patient.where.not(secondary_language: nil).length

  unmatchable_secondary_langs = get_all_unmamtchable_count('secondary_language')

  matchable_secondary_langs = total_secondary_lang_count - unmatchable_secondary_langs
  printf("\n\nRunning in LIVE MODE mode (CHANGES WILL BE SAVED)\n")
  printf("\n")
  printf('Press anything to begin...')
  gets

  Patient.find_each do |monitoree|
    unless monitoree[:primary_language].nil? # guarantees going forward that the primary_language exists
      currrent_language = monitoree[:primary_language].to_s.downcase
      if CUSTOM_TRANSLATIONS.keys.include?(currrent_language.to_sym)
        monitoree[:secondary_language] = 'spanish' if currrent_language == 'bilingual english/spanish'
        lang_iso_code = INVERTED_ISO_LOOKUP[CUSTOM_TRANSLATIONS[currrent_language.to_sym]]
        exposure_notes_language_long = get_long_notes_text(lang_iso_code, currrent_language)
        exposure_notes_language_short = get_short_notes_text(lang_iso_code, currrent_language)
        language_text = ''
        current_exposure_notes_length = monitoree[:exposure_notes] ? monitoree[:exposure_notes].length : 0
        if EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_long.length
          language_text = exposure_notes_language_long
        elsif EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_short.length
          language_text = exposure_notes_language_short
        end
        monitoree[:exposure_notes] = monitoree[:exposure_notes] ? monitoree[:exposure_notes] << language_text : language_text unless language_text.nil?
        monitoree[:primary_language] = lang_iso_code
      else
        lang_iso_code = match_language(currrent_language)
        if lang_iso_code.nil?
          unmatchable_lang = currrent_language
          while lang_iso_code.nil?
            printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
            printf("Unable to match language '#{unmatchable_lang}' for Patient ID #{monitoree[:id]}\n")
            printf("Type a 3-letter iso-code or a language name to assign this monitoree.\n('nil' is an acceptable entry)\n")
            printf("The system will confirm your input before continuing further.\n")
            printf('Enter Languge: ')
            unmatchable_lang = gets.chomp
            lang_iso_code = unmatchable_lang == 'nil' ? 'nil' : match_language(unmatchable_lang.to_s.downcase) # use the string nil to break out of the `while`
          end
          lang_iso_code = lang_iso_code == 'nil' ? nil : lang_iso_code
          total_patients_with_lang = Patient.where('lower(primary_language) = ?', monitoree[:primary_language]).length
          printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
          if lang_iso_code
            printf("The System was successfully able to match '#{unmatchable_lang}' to '#{LANGUAGES[lang_iso_code.to_sym]}'.\n")
          else
            printf("The System successfully registed your 'nil' entry.")
          end
          if total_patients_with_lang > 1
            printf("\nThere are #{total_patients_with_lang - 1} other Patient#{if (total_patients_with_lang - 1) > 1
                                                                                 's'
                                                                               end} with the language '#{currrent_language}' as their primary language.\n")
            printf("Enter '1' if you would like to change them all to '#{lang_iso_code || 'nil'}'\n")
            printf("Enter '2' if you would like to ONLY change this Monitoree to '#{lang_iso_code || 'nil'}'\n")
            printf("The System will ask what you want to do with the old language next.\n")
            printf("Please note if select Option 1, the System will attempt to include the previous language in the exposure notes for all future monitorees with this language.\n")
            printf('Your Input (1 or 2): ')
            user_input = gets.chomp
            if user_input.to_s == '1'
              CUSTOM_TRANSLATIONS[currrent_language.to_sym] = lang_iso_code
              printf("Successfully added a mapping from '#{currrent_language}' to '#{lang_iso_code || 'nil'}'\n")
            end
            if user_input.to_s == '2'
              # do nothing
            end
          end
          printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
          printf("The System now needs to decide what to do with the old language code.\n")
          printf("Please note the exact phrasing will be:\n")
          exposure_notes_language_long = get_long_notes_text(lang_iso_code, currrent_language)
          exposure_notes_language_short = get_short_notes_text(lang_iso_code, currrent_language)
          printf("If there is more than #{exposure_notes_language_long.length} characters free, the following will be appended to any Notes:\n")
          printf("\t#{exposure_notes_language_long}\n")
          printf("\nIf there is more than #{exposure_notes_language_short.length} characters free, the following will be appended to any Notes:\n")
          printf("\t#{exposure_notes_language_short}\n")
          printf("\nIf there are not #{exposure_notes_language_short.length} characters free, the Exposure Notes will not be updated and the data dropped.\n")
          printf("\nEnter '1' if you would like to attempt to include it in the 'Exposure Notes' field for this monitoree.\n")
          printf("Enter '2' if you would like to drop the data.\n")
          printf('Your Input (1 or 2): ')
          user_input = gets.chomp
          if user_input.to_s == '1'
            language_text = ''
            current_exposure_notes_length = monitoree[:exposure_notes] ? monitoree[:exposure_notes].length : 0
            if EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_long.length
              language_text = exposure_notes_language_long
            elsif EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_short.length
              language_text = exposure_notes_language_short
            end
            monitoree[:exposure_notes] = monitoree[:exposure_notes] ? monitoree[:exposure_notes] << language_text : language_text unless language_text.nil?
          end
          if user_input.to_s == '2'
            # do nothing
          end
        else
          monitoree[:primary_language] = lang_iso_code
        end
      end
    end
    unless monitoree[:secondary_language].nil? # guarantees going forward that the secondary_language exists
      currrent_language = monitoree[:secondary_language].to_s.downcase
      if CUSTOM_TRANSLATIONS.keys.include?(currrent_language.to_sym)
        lang_iso_code = INVERTED_ISO_LOOKUP[CUSTOM_TRANSLATIONS[currrent_language.to_sym]]
        exposure_notes_language_long = get_long_notes_text(lang_iso_code, currrent_language)
        exposure_notes_language_short = get_short_notes_text(lang_iso_code, currrent_language)
        monitoree[:secondary_language] = lang_iso_code
        language_text = ''
        current_exposure_notes_length = monitoree[:exposure_notes] ? monitoree[:exposure_notes].length : 0
        if EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_long.length
          language_text = exposure_notes_language_long
        elsif EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_short.length
          language_text = exposure_notes_language_short
        end
        monitoree[:exposure_notes] = monitoree[:exposure_notes] ? monitoree[:exposure_notes] << language_text : language_text unless language_text.nil?
      else
        lang_iso_code = match_language(currrent_language)
        if lang_iso_code.nil?
          unmatchable_lang = currrent_language
          while lang_iso_code.nil?
            printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
            printf("Unable to match language '#{unmatchable_lang}' for Patient ID #{monitoree[:id]}\n")
            printf("Type a 3-letter iso-code or a language name to assign this monitoree.\n('nil' is an acceptable entry)\n")
            printf("The system will confirm your input before continuing further.\n")
            printf('Enter Languge: ')
            unmatchable_lang = gets.chomp
            lang_iso_code = unmatchable_lang == 'nil' ? 'nil' : match_language(unmatchable_lang.to_s.downcase) # use the string nil to break out of the `while`
          end
          lang_iso_code = lang_iso_code == 'nil' ? nil : lang_iso_code
          total_patients_with_lang = Patient.where('lower(secondary_language) = ?', monitoree[:secondary_language]).length
          printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
          if lang_iso_code
            printf("The System was successfully able to match '#{unmatchable_lang}' to '#{LANGUAGES[lang_iso_code.to_sym]}'.\n")
          else
            printf("The System successfully registed your 'nil' entry.\n")
          end
          if total_patients_with_lang > 1
            printf("\nThere are #{total_patients_with_lang - 1} other Patient#{if (total_patients_with_lang - 1) > 1
                                                                                 's'
                                                                               end} with the language '#{currrent_language}' as their primary language.\n")
            printf("Enter '1' if you would like to change them all to '#{lang_iso_code || 'nil'}'\n")
            printf("Enter '2' if you would like to ONLY change this Monitoree to '#{lang_iso_code || 'nil'}'\n")
            printf("The System will ask what you want to do with the old language next.\n")
            printf("Please note if select Option 1, the System will attempt to include the previous language in the exposure notes for all future monitorees with this language.\n")
            printf('Your Input (1 or 2): ')
            user_input = gets.chomp
            if user_input.to_s == '1'
              CUSTOM_TRANSLATIONS[currrent_language.to_sym] = lang_iso_code
              printf("Successfully added a mapping from '#{currrent_language}' to '#{lang_iso_code || 'nil'}'\n")
            end
            if user_input.to_s == '2'
              # do nothing
            end
          end
          printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
          printf("The System now needs to decide what to do with the old language code.\n")
          printf("Please note the exact phrasing will be:\n")
          exposure_notes_language_long = get_long_notes_text(lang_iso_code, currrent_language)
          exposure_notes_language_short = get_short_notes_text(lang_iso_code, currrent_language)
          printf("If there is more than #{exposure_notes_language_long.length} characters free, the following will be appended to any Notes:\n")
          printf("\t#{exposure_notes_language_long}\n")
          printf("\nIf there is more than #{exposure_notes_language_short.length} characters free, the following will be appended to any Notes:\n")
          printf("\t#{exposure_notes_language_short}\n")
          printf("\nIf there are not #{exposure_notes_language_short.length} characters free, the Exposure Notes will not be updated and the data dropped.\n")
          printf("\nEnter '1' if you would like to attempt to include it in the 'Exposure Notes' field for this monitoree.\n")
          printf("Enter '2' if you would like to drop the data.\n")
          printf('Your Input (1 or 2): ')
          user_input = gets.chomp
          if user_input.to_s == '1'
            language_text = ''
            current_exposure_notes_length = monitoree[:exposure_notes] ? monitoree[:exposure_notes].length : 0
            if EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_long.length
              language_text = exposure_notes_language_long
            elsif EXPOSURE_NOTES_FIELD_MAX_LENGTH - current_exposure_notes_length >= exposure_notes_language_short.length
              language_text = exposure_notes_language_short
            end
            monitoree[:exposure_notes] = monitoree[:exposure_notes] ? monitoree[:exposure_notes] << language_text : language_text unless language_text.nil?
          end
          if user_input.to_s == '2'
            # do nothing
          end
        else
          monitoree[:secondary_language] = lang_iso_code
        end
      end
    end
    monitoree.save!
  end
  printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n")
  printf("System completed all Language translations successfully!\n")
  printf("\n-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-⋅-\n\n")
end

# rubocop:enable Metrics/BlockNesting
# rubocop:enable Style/MutableConstant
