class CreateCommonExposureCohorts < ActiveRecord::Migration[6.1]
  PATIENT_BATCH_SIZE = 5000

  def up
    create_table :common_exposure_cohorts do |t|
      t.references :patient, index: true

      t.string :cohort_type, index: true
      t.string :cohort_name, index: true
      t.string :cohort_location, index: true

      t.timestamps
    end

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

    ActiveRecord::Base.record_timestamps = false

    remove_column :patients, :member_of_a_common_exposure_cohort
    remove_column :patients, :member_of_a_common_exposure_cohort_type

    # TODO: update advanced filters and export presets

    ActiveRecord::Base.record_timestamps = true
  end

  def down
    ActiveRecord::Base.record_timestamps = false

    # TODO: update advanced filters and export presets

    add_column :patients, :member_of_a_common_exposure_cohort, :boolean
    add_column :patients, :member_of_a_common_exposure_cohort_type, :string, limit: 200

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

    ActiveRecord::Base.record_timestamps = true

    drop_table :common_exposure_cohorts
  end
end
