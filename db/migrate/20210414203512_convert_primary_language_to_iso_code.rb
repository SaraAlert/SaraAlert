# frozen_string_literal: true

# ConvertPrimaryLanguageToIsoCode: converts primary_languages to iso codes
class ConvertPrimaryLanguageToIsoCode < ActiveRecord::Migration[6.1]
  include Languages
  # Nothing in the following list is case sensitive
  TRANSLATION_LIST = {
    'Acoli' => ['acholi'],
    'American Sign Language' => ['Sign Languages', 'asl', 'sign language'],
    'bilingual spanish/english' => ['dad span/eng', 'span/eng'],
    'bilingual english/spanish' => ['ENG/SPAN', 'eng/braz'],
    'bosnian' => ['bos'],
    'Chinese' => ['Chinese (Cantonese)', 'Chinese (Mandarin)', 'Chinese (not specified)', 'Mandarin', 'manderin chinese'],
    'English' => ['E', 'ENGLIAH', 'ENHLISH', 'Emglish', 'Engiish', 'Engish', 'Englaih', 'England', 'Englislh', 'Englsh', 'Englsih', 'Englxish', 'Enlish',
                  'dad limited eng', 'parent eng'],
    'French' => ['FR', 'fre', 'lingala, french'],
    'filipino' => ['philippines'],
    'frisian' => ['frysian'],
    'haitian' => ['haitian creole', 'HAITIAN FRENCH CREOLE', 'Haitian Creole'],
    'Lao' => %w[Laos Laotian],
    'Marshallese' => ['marshalee'],
    'Panjabi' => ['punjabi'],
    'Persian' => ['Persian (Farsi)', 'farsi'],
    'Portuguese' => ['PORTG', 'PORTUG', 'lingala/portuguese', 'portguese', 'portugese'],
    'Somali' => ['somali, may maay', 'somali, may-maay'],
    'Spanish' => ['Espanol', 'SPAN', 'SpanishA', 'dad span'],
    'Telugu' => %w[pelugu Telegu],
    'Vietnamese' => ['vietamese'],
    'nil' => [' French-based (Other)', '1', '9', 'Chin', 'Creoles and pidgins', 'Dari', 'Jefferson', 'NA', 'No.', 'None', 'Other', 'RUNYORO', 'UND',
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
      key = nil if key == 'nil'
      normalized_key = Languages.normalize_and_get_language_code(key).to_s
      value.each do |language|
        custom_translations[language.to_sym] = ['bilingual english/spanish', 'bilingual spanish/english', nil].include?(key) ? key : normalized_key
      end
    end

    existing_primary_languages = Patient.where(purged: false).where.not(primary_language: nil).distinct.pluck(:primary_language)
    existing_secondary_languages = Patient.where(purged: false).where.not(secondary_language: nil).distinct.pluck(:secondary_language)
    # Create an translation in automatic_translations, unless we already have it defined in `custom_translations`
    (existing_primary_languages | existing_secondary_languages).each do |el|
      automatic_translations[el.to_sym] = (Languages.normalize_and_get_language_code(el).to_s || nil) unless custom_translations.key?(el.to_sym)
    end
    ActiveRecord::Base.transaction do
      automatic_translations.each do |key, value|
        # Patient records updated here are solely updated (no History Items included)
        Patient.where(purged: false).where(primary_language: key).update_all(primary_language: value)
        Patient.where(purged: false).where(secondary_language: key).update_all(secondary_language: value)
      end
      custom_translations.each do |key, value|
        key = key.to_s
        case value
        when 'bilingual english/spanish'
          insert_history_items(key, 'eng', true) if TRANSLATION_COMMENTS.include?(key)
          Patient.where(purged: false).where(primary_language: key).update_all({ primary_language: 'eng', secondary_language: 'spa' })
        when 'bilingual spanish/english'
          insert_history_items(key, 'spa', true) if TRANSLATION_COMMENTS.include?(key)
          Patient.where(purged: false).where(primary_language: key).update_all({ primary_language: 'spa', secondary_language: 'eng' })
        else
          insert_history_items(key, value, true) if TRANSLATION_COMMENTS.include?(key)
          Patient.where(purged: false).where(primary_language: key).update_all(primary_language: value)
          insert_history_items(key, value, false) if TRANSLATION_COMMENTS.include?(key)
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

  def insert_history_items(key, value, is_primary)
    note = "#{is_primary ? 'Primary' : 'Secondary'} language was listed as '#{key}' \
    which could not be matched to the standard language list. This monitoree’s #{is_primary ? 'primary' : 'secondary'} \
    language has been updated to '#{value.nil? ? 'blank' : Languages.all_languages[value.to_sym][:display]}'. You \
    may update this value."
    if is_primary
      execute <<-SQL.squish
        INSERT INTO histories (patient_id, created_by, comment, history_type, created_at, updated_at)
        SELECT id, 'Sara Alert System', "#{note}", 'System Note', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM patients
        WHERE purged = false AND primary_language = "#{key}"
      SQL
    else
      execute <<-SQL.squish
        INSERT INTO histories (patient_id, created_by, comment, history_type, created_at, updated_at)
        SELECT id, 'Sara Alert System', "#{note}", 'System Note', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM patients
        WHERE purged = false AND secondary_language = "#{key}"
      SQL
    end
  end
end
