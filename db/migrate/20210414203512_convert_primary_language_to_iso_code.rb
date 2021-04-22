# frozen_string_literal: true

class ConvertPrimaryLanguageToIsoCode < ActiveRecord::Migration[6.1]
  # Nothing in the following list is case sensitive
  TRANSLATION_LIST = {
    "Acoli": ['acholi'],
    "American Sign Language": ['Sign Languages', 'asl', 'sign language'],
    "bilingual spanish/english": ['dad span/eng', 'span/eng'],
    "bilingual english/spanish": ['ENG/SPAN', 'eng/braz'],
    "bosnian": ['bos'],
    "Chinese": ['Chinese (Cantonese)', 'Chinese (Mandarin)', 'Chinese (not specified)', 'Mandarin', 'manderin chinese'],
    "English": ['E', 'ENGLIAH', 'ENHLISH', 'Emglish', 'Engiish', 'Engish', 'Englaih', 'England', 'Englislh', 'Englsh', 'Englsih', 'Englxish', 'Enlish',
                'dad limited eng', 'parent eng'],
    "French": ['FR', 'fre', 'lingala, french'],
    "filipino": ['philippines'],
    "frisian": ['frysian'],
    "haitian": ['haitian creole', 'HAITIAN FRENCH CREOLE', 'Haitian Creole'],
    "Lao": %w[Laos Laotian],
    "Marshallese": ['marshalee'],
    "Panjabi": ['punjabi'],
    "Persian": ['Persian (Farsi)', 'farsi'],
    "Portuguese": ['PORTG', 'PORTUG', 'lingala/portuguese', 'portguese', 'portugese'],
    "Somali": ['somali, may maay', 'somali, may-maay'],
    "Spanish": ['Espanol', 'SPAN', 'SpanishA', 'dad span'],
    "Telugu": %w[pelugu Telegu],
    "Vietnamese": ['vietamese'],
    'nil': [' French-based (Other)', '1', '9', 'Chin', 'Creoles and pidgins', 'Dari', 'Jefferson', 'NA', 'No.', 'None', 'Other', 'RUNYORO', 'UND',
            'Undetermined', 'Unknown', 'afro-asiatic languages', 'no']
  }.freeze

  # For some translations we want to leave comments explaining the translation
  # For example, it doesnt make sense to tell the User that we've translated "ENGLLISH" to "English"
  # But if we translate 'dad span/eng' to spanish and english, it's worth telling them in a note
  # Only for values listed below will the system create History items explaining the language mapping
  TRANSLATION_COMMENTS = [' French-based (Other)', 'Chin', 'Chinese (Cantonese)', 'Chinese (Mandarin)',
                          'Chinese (not specified)', 'Creoles and pidgins', 'Dari', 'HAITIAN FRENCH CREOLE', 'Haitian Creole', 'Jefferson', 'Laos',
                          'Laotian ', 'Mandarin', 'RUNYORO', 'Sign Languages', 'acholi', 'afro-asiatic languages', 'dad limited eng', 'dad span',
                          'dad span/eng', 'eng/braz', 'farsi', 'lingala, french', 'lingala/portuguese', 'manderin chinese', 'no', 'parent eng',
                          'somali, may maay', 'somali, may-maay'].freeze

  def up
    add_column :patients, :legacy_primary_language, :string
    add_column :patients, :legacy_secondary_language, :string
    execute <<-SQL.squish
        UPDATE patients
        SET legacy_primary_language = primary_language, legacy_secondary_language = secondary_language
        WHERE purged = FALSE
    SQL

    # automatic_translations will take the format of { 'English' : 'eng' }
    # Where `English` is plucked directly from the DB
    automatic_translations = {}

    # custom_translations will take the format of { 'engish' : 'English', 'englsh' : 'English'...etc }
    # It is merely a re-formatting of the TRANSLATION_LIST above
    custom_translations = {}
    TRANSLATION_LIST.each do |key, value|
      key = key == :nil ? nil : key.to_s
      value.each do |language|
        custom_translations[language.to_sym] = if ['bilingual english/spanish', 'bilingual spanish/english', nil].include?(key)
                                                 key
                                               else
                                                 match_language(key).to_s
                                               end
      end
    end

    existing_primary_languages = Patient.where(purged: false).where.not(primary_language: nil).distinct.pluck(:primary_language)
    existing_secondary_languages = Patient.where(purged: false).where.not(secondary_language: nil).distinct.pluck(:secondary_language)
    # Create an translation in automatic_translations, unless we already have it defined in `custom_translations`
    (existing_primary_languages | existing_secondary_languages).each do |el|
      automatic_translations[el.to_sym] = (match_language(el).to_s || nil) unless custom_translations.key?(el.to_sym)
    end
    ActiveRecord::Base.transaction do
      automatic_translations.each do |key, value|
        # Patient records updated here are solely updated (no History Items included)
        Patient.where(purged: false).where(primary_language: key).update_all(primary_language: value)
        Patient.where(purged: false).where(secondary_language: key).update_all(secondary_language: value)
      end
      custom_translations.each do |key, value|
        key = key.to_s
        if value === 'bilingual english/spanish'
          Patient.where(purged: false).where(primary_language: key).update_all({ primary_language: 'eng', secondary_language: 'spa' })
        elsif value === 'bilingual spanish/english'
          Patient.where(purged: false).where(primary_language: key).update_all({ primary_language: 'spa', secondary_language: 'eng' })
        elsif TRANSLATION_COMMENTS.include?(key)
          note = "Primary language was listed as '#{key}' \
                which could not be matched to the standard language list. This monitoree’s primary \
                language has been updated to '#{value.nil? ? 'blank' : Languages.all_languages[value.to_sym][:display]}'. You \
                may update this value."
          execute <<-SQL.squish
                INSERT INTO histories (patient_id,created_by,comment,history_type,created_at,updated_at)
                SELECT id, 'Sara Alert System', "#{note}", 'System Note', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                FROM patients
                WHERE purged = false AND primary_language = "#{key}"
          SQL
          Patient.where(purged: false).where(primary_language: key).update_all(primary_language: value)

          note = "Secondary language was listed as '#{key}' \
                which could not be matched to the standard language list. This monitoree’s secondary \
                language has been updated to '#{value.nil? ? 'blank' : Languages.all_languages[value.to_sym][:display]}'. You \
                may update this value."
          execute <<-SQL.squish
                INSERT INTO histories (patient_id,created_by,comment,history_type,created_at,updated_at)
                SELECT id, 'Sara Alert System', "#{note}", 'System Note', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                FROM patients
                WHERE purged = false AND secondary_language = "#{key}"
          SQL
          Patient.where(purged: false).where(secondary_language: key).update_all(secondary_language: value)
        end
      end
    end
  end

  def down
    execute <<-SQL.squish
        UPDATE patients SET primary_language = legacy_primary_language, secondary_language = legacy_secondary_language
    SQL

    remove_column :patients, :legacy_primary_language
    remove_column :patients, :legacy_secondary_language

    # Destroy all System Notes that contain the text `language was listed as`
    History.where('history_type = ? AND comment like ?', 'System Note', '%language was listed as%').destroy_all
  end

  def match_language(lang)
    return nil if lang.nil?

    lang = lang.to_s.downcase.strip
    matched_language = nil
    matched_language = lang.to_sym if Languages.all_languages[lang.to_sym].present?
    return matched_language unless matched_language.nil?

    matched_language = Languages.all_languages.find { |_key, val| val[:display]&.casecmp(lang)&.zero? }
    # [:fra, {:display=>"French", :iso6391code=>"fr", :system=>"iso639-2t" }]
    # matched_language will take the form of the above, and we want to return the 3-letter code at [0]
    return matched_language[0] unless matched_language.nil?

    matched_language = Languages.all_languages.find { |_key, val| val[:iso6391code]&.casecmp(lang)&.zero? }
    return matched_language[0] unless matched_language.nil?

    matched_language
  end
end
