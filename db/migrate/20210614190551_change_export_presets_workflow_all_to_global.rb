class ChangeExportPresetsWorkflowAllToGlobal < ActiveRecord::Migration[6.1]
  # Rename the 'all' workflow to 'global' in export presets
  def up
    ActiveRecord::Base.record_timestamps = false

    # Parse and modify the data in memory, because the JSON to modify is stored as a string in the database
    UserExportPreset.all.in_batches do |batch|
      batch.each do |uep|
        config = JSON.parse(uep.config)
        if config.dig('data', 'patients', 'query', 'workflow') == 'all'
          config['data']['patients']['query']['workflow'] = 'global'
          uep.update!(config: config.to_json)
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
  end

  # Revert the 'global' workflow back to 'all' in export presets
  def down
    ActiveRecord::Base.record_timestamps = false

    # Parse and modify the data in memory, because the JSON to modify is stored as a string in the database
    UserExportPreset.all.in_batches do |batch|
      batch.each do |uep|
        config = JSON.parse(uep.config)
        if config.dig('data', 'patients', 'query', 'workflow') == 'global'
          config['data']['patients']['query']['workflow'] = 'all'
          uep.update!(config: config.to_json)
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
  end
end
