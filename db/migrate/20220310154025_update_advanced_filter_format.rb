class UpdateAdvancedFilterFormat < ActiveRecord::Migration[6.1]
  include AdvancedFilterConstants

  def up
    ActiveRecord::Base.transaction do
      # Migrate saved advanced filters
      UserFilter.all.each do |uf|
          contents = JSON.parse(uf[:contents])
          migrate_advanced_filter_contents(contents)
          uf.update!(contents: contents.to_json)
      end

      # Migrate advanced filters in saved export presets
      UserExportPreset.all.each do |uep|
        config = JSON.parse(uep[:config])
        contents = config.dig('data', 'patients', 'query', 'filter')
        migrate_advanced_filter_contents(contents)
        config['data']['patients']['query']['filter'] = contents
        uep.update!(config: config.to_json)
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      # Rollback saved advanced filters
      UserFilter.all.each.each do |uf|
        user = User.find(uf.user_id)
        contents = JSON.parse(uf[:contents])
        rollback_advanced_filter_contents(contents, user)
        uf.update!(contents: contents.to_json)
      end

      # Rollback advanced filters in saved export presets
      UserExportPreset.all.each do |uep|
        user = User.find(uep.user_id)
        config = JSON.parse(uep[:config])
        contents = config.dig('data', 'patients', 'query', 'filter')
        rollback_advanced_filter_contents(contents, user)
        config['data']['patients']['query']['filter'] = contents
        uep.update!(config: config.to_json)
      end
    end
  end

  def migrate_advanced_filter_contents(contents)
    contents&.each do |content|
      content['name'] = content['filterOption']['name'] == 'continous-exposure' ? 'continuous-exposure' : content['filterOption']['name']
      content.delete('filterOption')
    end
  end

  def rollback_advanced_filter_contents(contents, user)
    contents&.each do |content|
      af_option = advanced_filter_options(user).find { |af| af[:name] == content['name'] }
      content['filterOption'] = af_option
      content['filterOption']['name'] = 'continous-exposure' if content['name'] == 'continuous-exposure'
      content.delete('name')
    end
  end
end
