# This migration was created to address the issue that our isolation asymptomatic non test based definition was previously using the latest positive lab rather
# than the first positive lab as outlined by the CDC (https://www.cdc.gov/coronavirus/2019-ncov/hcp/disposition-in-home-patients.html). Since the latest
# positive lab is no longer a field used for anything, we've decided to replace the field entirely with first positive lab.
class ReplaceLatestPositiveLabWithFirstPositiveLabOnPatients < ActiveRecord::Migration[6.1]
  def up
    add_column :patients, :first_positive_lab_at, :date, index: true
    remove_column :patients, :latest_positive_lab_at

    # populate :first_positive_lab_at
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, MIN(specimen_collection) AS first_positive_lab_at
        FROM laboratories
        WHERE result = 'positive'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.first_positive_lab_at = t.first_positive_lab_at
    SQL
  end

  def down
    add_column :patients, :latest_positive_lab_at, :date, index: true
    remove_column :patients, :first_positive_lab_at

    # populate :latest_positive_lab_at
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, MAX(specimen_collection) AS latest_positive_lab_at
        FROM laboratories
        WHERE result = 'positive'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_positive_lab_at = t.latest_positive_lab_at
    SQL
  end
end
