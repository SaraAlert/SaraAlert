class RemoveShortenedQuarantineFilters < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.transaction do
      # Migrate saved advanced filters
      relevant_filters.each do |uf|
        contents = JSON.parse(uf[:contents])
        contents = migrate_advanced_filter_contents(contents)
        if contents.empty?
          uf.destroy
        else
          uf.update!(contents: contents.to_json)
        end
      end

      # Migrate advanced filters in saved export presets
      relevant_export_presets.each do |uep|
        config = JSON.parse(uep[:config])
        contents = config.dig('data', 'patients', 'query', 'filter')
        contents = migrate_advanced_filter_contents(contents)
        config['data']['patients']['query']['filter'] = contents
        uep.update!(config: config.to_json)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def migrate_advanced_filter_contents(contents)
    contents.select { |content| %w[seven-day-quarantine ten-day-quarantine].exclude?(content['filterOption']['name']) }
  end

  def relevant_filters
    UserFilter.where('contents LIKE "%seven-day-quarantine%"').or(
      UserFilter.where('contents LIKE "%ten-day-quarantine%"')
    )
  end

  def relevant_export_presets
    UserExportPreset.where('config LIKE "%seven-day-quarantine%"').or(
      UserExportPreset.where('config LIKE "%ten-day-quarantine%"')
    )
  end
end
