class CreateCommonExposureCohorts < ActiveRecord::Migration[6.1]
  PATIENT_BATCH_SIZE = 5000
  FILTER_BATCH_SIZE = 1000

  OLD_COHORT_FILTER_OPTION = {
    name: 'cohort',
    title: 'Common Exposure Cohort Name (Text)',
    description: 'Monitoree common exposure cohort name or description',
    type: 'search'
  }.deep_stringify_keys.freeze

  NEW_COHORT_FILTER_OPTION = {
    name: 'common-exposure-cohort',
    title: 'Common Exposure Cohort (Combination)',
    description: 'Monitorees with specified Common Exposure Cohort criteria',
    type: 'combination',
    tooltip: 'Returns records that contain at least one Common Exposure Cohort entry that meets all user-specified criteria (e.g., searching for a specific '\
             'Common Exposure Cohort Type and Name/Description will only return records containing at least one Common Exposure Cohort entry with matching '\
             'values in both fields).',
    fields: [
      {
        name: 'cohort-type',
        title: 'cohort type',
        type: 'select',
        options: CommonExposureCohort::VALID_COHORT_TYPES.reject(&:nil?)
      },
      {
        name: 'cohort-name',
        title: 'cohort name/description',
        type: 'select',
        options: []
      },
      {
        name: 'cohort-location',
        title: 'cohort location',
        type: 'select',
        options: []
      }
    ]
  }.deep_stringify_keys.freeze

  def up
    create_table :common_exposure_cohorts do |t|
      t.references :patient, index: true

      t.string :cohort_type, index: true
      t.string :cohort_name, index: true
      t.string :cohort_location, index: true

      t.timestamps
    end

    ActiveRecord::Base.record_timestamps = false

    begin
      ActiveRecord::Base.transaction do
        # Create common exposure cohorts based on old field
        Patient.where.not(member_of_a_common_exposure_cohort_type: [nil, '']).in_batches(of: PATIENT_BATCH_SIZE).each do |batch_group|
          common_exposure_cohorts = []
          batch_group.pluck(:id, :member_of_a_common_exposure_cohort_type, :created_at).each do |(patient_id, cohort_name, created_at)|
            common_exposure_cohorts << CommonExposureCohort.new(
              patient_id: patient_id,
              cohort_name: cohort_name,
              created_at: created_at,
              updated_at: created_at
            )
          end
          CommonExposureCohort.import! common_exposure_cohorts
        end

        # Migrate saved advanced filters
        UserFilter.where('contents LIKE "%cohort%"').in_batches(of: FILTER_BATCH_SIZE) do |batch|
          batch.each do |uf|
            contents = JSON.parse(uf[:contents])
            migrate_advanced_filter_contents(contents)
            uf.update!(contents: contents.to_json)
          end
        end

        # Migrate saved export presets
        UserExportPreset.where('config LIKE "%cohort%"').in_batches(of: FILTER_BATCH_SIZE) do |batch|
          batch.each do |uep|
            config = JSON.parse(uep[:config])
            contents = config.dig('data', 'patients', 'query', 'filter')
            migrate_advanced_filter_contents(contents)
            config['data']['patients']['query']['filter'] = contents
            uep.update!(config: config.to_json)
          end
        end
      end
    rescue StandardError
      drop_table :common_exposure_cohorts
    else
      remove_column :patients, :member_of_a_common_exposure_cohort
      remove_column :patients, :member_of_a_common_exposure_cohort_type
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end

  def down
    add_column :patients, :member_of_a_common_exposure_cohort, :boolean
    add_column :patients, :member_of_a_common_exposure_cohort_type, :string, limit: 200

    ActiveRecord::Base.record_timestamps = false

    begin
      ActiveRecord::Base.transaction do
        # Update old field with common exposure cohorts
        Patient.where_assoc_exists(:common_exposure_cohorts).in_batches(of: PATIENT_BATCH_SIZE).each do |batch_group|
          updates = {}
          CommonExposureCohort.where(patient_id: batch_group.pluck(:id)).order(:updated_at).each do |common_exposure_cohort|
            updates[common_exposure_cohort[:patient_id]] = {
              member_of_a_common_exposure_cohort: true,
              member_of_a_common_exposure_cohort_type: common_exposure_cohort.cohort_name ||
                                                      common_exposure_cohort.cohort_type ||
                                                      common_exposure_cohort.cohort_location
            }
          end
          Patient.update(updates.keys, updates.values)
        end

        # Update saved advanced filters
        UserFilter.where('contents LIKE "%common-exposure-cohort%"').in_batches(of: FILTER_BATCH_SIZE) do |batch|
          batch.each do |uf|
            contents = JSON.parse(uf[:contents])
            rollback_advanced_filter_contents(contents)
            uf.update!(contents: contents.to_json)
          end
        end

        # Update saved export presets
        UserExportPreset.where('config LIKE "%common-exposure-cohort%"').in_batches(of: FILTER_BATCH_SIZE) do |batch|
          batch.each do |uep|
            config = JSON.parse(uep[:config])
            contents = config.dig('data', 'patients', 'query', 'filter')
            rollback_advanced_filter_contents(contents)
            config['data']['patients']['query']['filter'] = contents
            uep.update!(config: config.to_json)
          end
        end
      end
    rescue StandardError
      remove_column :patients, :member_of_a_common_exposure_cohort
      remove_column :patients, :member_of_a_common_exposure_cohort_type
    else
      drop_table :common_exposure_cohorts
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end

  def migrate_advanced_filter_contents(contents)
    contents.each do |fo|
      next unless fo.dig('filterOption', 'name') == 'cohort'

      fo['filterOption'] = NEW_COHORT_FILTER_OPTION
      fo['value'] = [{ name: 'cohort-name', value: fo['value'] }.deep_stringify_keys]
    end
  end

  def rollback_advanced_filter_contents(contents)
    contents.map do |fo|
      next unless fo.dig('filterOption', 'name') == 'common-exposure-cohort'

      fo['filterOption'] = OLD_COHORT_FILTER_OPTION
      fo['value'] = fo['value']&.first['value']
    end
  end
end
