class UpdateVaccineProductNamesToMatchCdc < ActiveRecord::Migration[6.1]
  def up
    # Update all vaccine names which have changed
    Vaccine.where(product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)').update_all(product_name: 'Moderna COVID-19 Vaccine (non-US Spikevax)')
    Vaccine.where(product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)').update_all(product_name: 'Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)')
    Vaccine.where(product_name: 'AstraZeneca COVID-19 Vaccine (Non-US tradenames: VAXZEVRIA, COVISHIELD)').update_all(product_name: 'AstraZeneca COVID-19 Vaccine (Non-US tradenames include VAXZEVRIA, COVISHIELD)')
    Vaccine.where(product_name: 'Coronavac (Sinovac) COVID-19 Vaccine (Non-US)').update_all(product_name: 'Coronavac (Sinovac) COVID-19 Vaccine')
    Vaccine.where(product_name: 'Sinopharm (BIBP) COVID-19 Vaccine (Non-US)').update_all(product_name: 'Sinopharm (BIBP) COVID-19 Vaccine')

    # Update all saved user_export_presets
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)', 'Moderna COVID-19 Vaccine (non-US Spikevax)') WHERE config REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', 'Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)') WHERE config REGEXP 'Pfizer'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'AstraZeneca COVID-19 Vaccine (Non-US tradenames: VAXZEVRIA, COVISHIELD)', 'AstraZeneca COVID-19 Vaccine (Non-US tradenames include VAXZEVRIA, COVISHIELD)') WHERE config REGEXP 'AstraZeneca'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Coronavac (Sinovac) COVID-19 Vaccine (Non-US)', 'Coronavac (Sinovac) COVID-19 Vaccine') WHERE config REGEXP 'Coronavac'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Sinopharm (BIBP) COVID-19 Vaccine (Non-US)', 'Sinopharm (BIBP) COVID-19 Vaccine') WHERE config REGEXP 'Sinopharm'")).execute

    # Update all saved user_filters
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)', 'Moderna COVID-19 Vaccine (non-US Spikevax)') WHERE contents REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)', 'Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)') WHERE contents REGEXP 'Pfizer'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'AstraZeneca COVID-19 Vaccine (Non-US tradenames: VAXZEVRIA, COVISHIELD)', 'AstraZeneca COVID-19 Vaccine (Non-US tradenames include VAXZEVRIA, COVISHIELD)') WHERE contents REGEXP 'AstraZeneca'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Coronavac (Sinovac) COVID-19 Vaccine (Non-US)', 'Coronavac (Sinovac) COVID-19 Vaccine') WHERE contents REGEXP 'Coronavac'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Sinopharm (BIBP) COVID-19 Vaccine (Non-US)', 'Sinopharm (BIBP) COVID-19 Vaccine') WHERE contents REGEXP 'Sinopharm'")).execute
  end

  def down
    # Revert the vaccine names which have changed
    Vaccine.where(product_name: 'Moderna COVID-19 Vaccine (non-US Spikevax)').update_all(product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)')
    Vaccine.where(product_name: 'Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)').update_all(product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)')
    Vaccine.where(product_name: 'AstraZeneca COVID-19 Vaccine (Non-US tradenames include VAXZEVRIA, COVISHIELD)').update_all(product_name: 'AstraZeneca COVID-19 Vaccine (Non-US tradenames: VAXZEVRIA, COVISHIELD)')
    Vaccine.where(product_name: 'Coronavac (Sinovac) COVID-19 Vaccine').update_all(product_name: 'Coronavac (Sinovac) COVID-19 Vaccine (Non-US)')
    Vaccine.where(product_name: 'Sinopharm (BIBP) COVID-19 Vaccine').update_all(product_name: 'Sinopharm (BIBP) COVID-19 Vaccine (Non-US)')

    # Revert the saved user_export_presets
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Moderna COVID-19 Vaccine (non-US Spikevax)', 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)') WHERE config REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)', 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)') WHERE config REGEXP 'Pfizer'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Coronavac (Sinovac) COVID-19 Vaccine', 'Coronavac (Sinovac) COVID-19 Vaccine (Non-US)') WHERE config REGEXP 'Coronovac'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Sinopharm (BIBP) COVID-19 Vaccine', 'Sinopharm (BIBP) COVID-19 Vaccine (Non-US)') WHERE config REGEXP 'Sinopharm'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'AstraZeneca COVID-19 Vaccine (Non-US tradenames include VAXZEVRIA, COVISHIELD)', 'AstraZeneca COVID-19 Vaccine (Non-US tradenames: VAXZEVRIA, COVISHIELD)') WHERE config REGEXP 'AstraZeneca'")).execute

    # Revert the saved user_filter_presets
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Moderna COVID-19 Vaccine (non-US Spikevax)', 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)') WHERE contents REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Pfizer-BioNTech COVID-19 Vaccine (COMIRNATY)', 'Pfizer-BioNTech COVID-19 Vaccine (Tradename: COMIRNATY)') WHERE contents REGEXP 'Pfizer'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Coronavac (Sinovac) COVID-19 Vaccine', 'Coronavac (Sinovac) COVID-19 Vaccine (Non-US)') WHERE contents REGEXP 'Coronovac'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Sinopharm (BIBP) COVID-19 Vaccine', 'Sinopharm (BIBP) COVID-19 Vaccine (Non-US)') WHERE contents REGEXP 'Sinopharm'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'AstraZeneca COVID-19 Vaccine (Non-US tradenames include VAXZEVRIA, COVISHIELD)', 'AstraZeneca COVID-19 Vaccine (Non-US tradenames: VAXZEVRIA, COVISHIELD)') WHERE contents REGEXP 'AstraZeneca'")).execute
  end
end
