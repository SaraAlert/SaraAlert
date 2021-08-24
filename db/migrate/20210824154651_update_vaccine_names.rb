class UpdateVaccineNames < ActiveRecord::Migration[6.1]
  def change
    # purge job deletes vaccines
    Vaccine.where(product_name: 'Moderna COVID-19 Vaccine').update_all(product_name: 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)')
    Vaccine.where(product_name: 'Pfizer-BioNTech COVID-19 Vaccine').update_all(product_name: 'Pfizer-BioNTech COVID-19 Vaccine (Non-US tradename: COMIRNATY)')

    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Moderna COVID-19 Vaccine', 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)') WHERE config REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_export_presets SET config = REPLACE(config, 'Pfizer-BioNTech COVID-19 Vaccine', 'Pfizer-BioNTech COVID-19 Vaccine (Non-US tradename: COMIRNATY)') WHERE config REGEXP 'Pfizer'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Moderna COVID-19 Vaccine', 'Moderna COVID-19 Vaccine (Non-US tradename: Spikevax)') WHERE contents REGEXP 'Moderna'")).execute
    ActiveRecord::Base.connection.raw_connection.prepare(Arel.sql("UPDATE user_filters SET contents = REPLACE(contents, 'Pfizer-BioNTech COVID-19 Vaccine', 'Pfizer-BioNTech COVID-19 Vaccine (Non-US tradename: COMIRNATY)') WHERE contents REGEXP 'Pfizer'")).execute
  end
end
