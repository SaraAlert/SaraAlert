class UpdateVaccineNames < ActiveRecord::Migration[6.1]
  def up
    # purge job deletes vaccines
    Vaccine.where(product_name: 'Moderna COVID-19 Vaccine').update_all(product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)')
    Vaccine.where(product_name: 'Pfizer-BioNTech COVID-19 Vaccine').update_all(product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)')

    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Moderna COVID-19 Vaccine', 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)') WHERE config REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Pfizer-BioNTech COVID-19 Vaccine', 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)') WHERE config REGEXP 'Pfizer'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Moderna COVID-19 Vaccine', 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)') WHERE contents REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Pfizer-BioNTech COVID-19 Vaccine', 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)') WHERE contents REGEXP 'Pfizer'")).execute
  end

  def down
    Vaccine.where(dose_number: '3').update_all(dose_number: 'Unknown')

    Vaccine.where(product_name: 'Moderna COVID-19 Vaccine').update_all(product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)')
    Vaccine.where(product_name: 'Pfizer-BioNTech COVID-19 Vaccine').update_all(product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)')
    # New Vaccines will get set to unknown
    Vaccine.where(product_name: ['AstraZeneca COVID-19 Vaccine (Non-US tradenames: VAXZEVRIA, COVISHIELD)', 'Coronavac (Sinovac) COVID-19 Vaccine (Non-US)', 'Sinopharm (BIBP) COVID-19 Vaccine (Non-US)']).update_all(product_name: 'Unknown')

    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)', 'Moderna COVID-19 Vaccine') WHERE config REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', 'Pfizer-BioNTech COVID-19 Vaccine') WHERE config REGEXP 'Pfizer'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Coronavac (Sinovac) COVID-19 Vaccine (Non-US)', 'Unknown') WHERE config REGEXP 'Coronovac'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Sinopharm (BIBP) COVID-19 Vaccine (Non-US)', 'Unknown') WHERE config REGEXP 'Sinopharm'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'AstraZeneca COVID-19 Vaccine (Non-US tradenames: VAXZEVRIA, COVISHIELD)', 'Unknown') WHERE config REGEXP 'AstraZeneca'")).execute

    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)', 'Moderna COVID-19 Vaccine') WHERE contents REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', 'Pfizer-BioNTech COVID-19 Vaccine') WHERE contents REGEXP 'Pfizer'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Coronavac (Sinovac) COVID-19 Vaccine (Non-US)', 'Unknown') WHERE contents REGEXP 'Coronovac'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Sinopharm (BIBP) COVID-19 Vaccine (Non-US)', 'Unknown') WHERE contents REGEXP 'Sinopharm'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'AstraZeneca COVID-19 Vaccine (Non-US tradenames: VAXZEVRIA, COVISHIELD)', 'Unknown') WHERE contents REGEXP 'AstraZeneca'")).execute
  end
end
