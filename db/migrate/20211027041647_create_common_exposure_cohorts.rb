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
             'values in both fields). Leaving these fields blank will not filter out any monitorees.',
    fields: [
      {
        name: 'cohort-type',
        title: 'cohort type',
        type: 'multi',
        options: CommonExposureCohort::VALID_COHORT_TYPES.reject(&:nil?)
      },
      {
        name: 'cohort-name',
        title: 'cohort name/description',
        type: 'multi',
        options: []
      },
      {
        name: 'cohort-location',
        title: 'cohort location',
        type: 'multi',
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
        # Auto populate boolean risk factors (this cannot be reversed)
        autopopulate_boolean_risk_factors

        # Create common exposure cohorts based on old field
        Patient.where(purged: false).where.not(member_of_a_common_exposure_cohort_type: [nil, '']).in_batches(of: PATIENT_BATCH_SIZE).each do |batch_group|
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

        # Migrate advanced filters in saved export presets
        UserExportPreset.where('config LIKE "%cohort%"').in_batches(of: FILTER_BATCH_SIZE) do |batch|
          batch.each do |uep|
            config = JSON.parse(uep[:config])
            contents = config.dig('data', 'patients', 'query', 'filter')
            migrate_advanced_filter_contents(contents)
            config['data']['patients']['query']['filter'] = contents
            uep.update!(config: config.to_json)
          end
        end

        # Migrate selected common exposure cohorts in saved export presets
        UserExportPreset.where('config LIKE "%member_of_a_common_exposure_cohort_type%"').in_batches(of: FILTER_BATCH_SIZE) do |batch|
          batch.each do |uep|
            config = JSON.parse(uep[:config])
            checked = config.dig('data', 'patients', 'checked')
            if checked.include?('member_of_a_common_exposure_cohort_type')
              config['data']['common_exposure_cohorts'] = {
                checked: ImportExportConstants::COMMON_EXPOSURE_COHORT_FIELD_NAMES.keys,
                expanded: [],
                query: {}
              }
              checked.delete('member_of_a_common_exposure_cohort_type')
              config['data']['patients']['checked'] = checked
              uep.update!(config: config.to_json)
            end
          end
        end
      end
    rescue StandardError => e
      puts 'An error has occured during the migration, reverting changes...'
      puts e

      drop_table :common_exposure_cohorts

      # Raise another error to fail the migration
      raise StandardError
    else
      remove_column :patients, :member_of_a_common_exposure_cohort_type
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end

  def down
    add_column :patients, :member_of_a_common_exposure_cohort_type, :string, limit: 200

    ActiveRecord::Base.record_timestamps = false

    begin
      ActiveRecord::Base.transaction do
        # Update old field with common exposure cohorts
        Patient.where(purged: false).where_assoc_exists(:common_exposure_cohorts).in_batches(of: PATIENT_BATCH_SIZE).each do |batch_group|
          updates = {}
          CommonExposureCohort.where(patient_id: batch_group.pluck(:id)).order(:updated_at).each do |common_exposure_cohort|
            updates[common_exposure_cohort[:patient_id]] = {
              member_of_a_common_exposure_cohort_type: common_exposure_cohort.cohort_name ||
                                                       common_exposure_cohort.cohort_type ||
                                                       common_exposure_cohort.cohort_location
            }
          end
          Patient.update(updates.keys, updates.values)
        end

        # Rollback saved advanced filters
        UserFilter.where('contents LIKE "%common-exposure-cohort%"').in_batches(of: FILTER_BATCH_SIZE) do |batch|
          batch.each do |uf|
            contents = JSON.parse(uf[:contents])
            rollback_advanced_filter_contents(contents)
            uf.update!(contents: contents.to_json)
          end
        end

        # Rollback advanced filters in saved export presets
        UserExportPreset.where('config LIKE "%common-exposure-cohort%"').in_batches(of: FILTER_BATCH_SIZE) do |batch|
          batch.each do |uep|
            config = JSON.parse(uep[:config])
            contents = config.dig('data', 'patients', 'query', 'filter')
            rollback_advanced_filter_contents(contents)
            config['data']['patients']['query']['filter'] = contents
            uep.update!(config: config.to_json)
          end
        end

        # Rollback selected common exposure cohorts in saved export presets
        UserExportPreset.where('config LIKE "%common_exposure_cohorts%"').in_batches(of: FILTER_BATCH_SIZE) do |batch|
          batch.each do |uep|
            config = JSON.parse(uep[:config])
            if (config['data'].include?('common_exposure_cohorts'))
              checked = config.dig('data', 'patients', 'checked')
              checked.push('member_of_a_common_exposure_cohort_type')
              config['data']['patients']['checked'] = checked
              config['data'].delete('common_exposure_cohorts')
              uep.update!(config: config.to_json)
            end
          end
        end
      end
    rescue StandardError => e
      puts 'An error has occured during the rollback, reverting changes...'
      puts e

      remove_column :patients, :member_of_a_common_exposure_cohort_type

      # Raise another error to fail the migration
      raise StandardError
    else
      drop_table :common_exposure_cohorts
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end

  def autopopulate_boolean_risk_factors
    execute <<-SQL.squish
      UPDATE patients
      SET contact_of_known_case = true
      WHERE purged = false AND contact_of_known_case_id IS NOT NULL
    SQL

    execute <<-SQL.squish
      UPDATE patients
      SET was_in_health_care_facility_with_known_cases = true
      WHERE purged = false AND was_in_health_care_facility_with_known_cases_facility_name IS NOT NULL
    SQL

    execute <<-SQL.squish
      UPDATE patients
      SET laboratory_personnel = true
      WHERE purged = false AND laboratory_personnel_facility_name IS NOT NULL
    SQL

    execute <<-SQL.squish
      UPDATE patients
      SET healthcare_personnel = true
      WHERE purged = false AND healthcare_personnel_facility_name IS NOT NULL
    SQL

    execute <<-SQL.squish
      UPDATE patients
      SET member_of_a_common_exposure_cohort = true
      WHERE purged = false AND member_of_a_common_exposure_cohort_type IS NOT NULL
    SQL
  end

  def migrate_advanced_filter_contents(contents)
    contents&.each do |fo|
      next unless fo.dig('filterOption', 'name') == 'cohort'

      fo['filterOption'] = NEW_COHORT_FILTER_OPTION
      fo['value'] = [{ name: 'cohort-name', value: fo['value'] }.deep_stringify_keys]
    end
  end

  def rollback_advanced_filter_contents(contents)
    contents&.each do |fo|
      next unless fo.dig('filterOption', 'name') == 'common-exposure-cohort'

      fo['filterOption'] = OLD_COHORT_FILTER_OPTION
      fo['value'] = fo['value']&.first['value']
    end
  end
end
