class AddLinelistFieldsToPatients < ActiveRecord::Migration[6.0]
  def up
    add_column :patients, :latest_assessment_at, :datetime, index: true
    add_column :patients, :latest_fever_or_fever_reducer_at, :datetime, index: true
    add_column :patients, :latest_positive_lab_at, :date, index: true
    add_column :patients, :negative_lab_count, :integer, default: 0, index: true
    add_column :patients, :latest_transfer_at, :datetime, index: true
    add_column :patients, :latest_transfer_from, :integer, index: true

    # populate :latest_assessment_at
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, MAX(created_at) AS latest_assessment_at
        FROM assessments
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_assessment_at = t.latest_assessment_at
    SQL

    # populate :latest_fever_or_fever_reducer_at
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT assessments.patient_id, MAX(assessments.created_at) AS latest_fever_or_fever_reducer_at
        FROM assessments
        INNER JOIN conditions ON assessments.id = conditions.assessment_id
        INNER JOIN symptoms ON conditions.id = symptoms.condition_id
        WHERE (symptoms.name = 'fever' OR symptoms.name = 'used-a-fever-reducer') AND symptoms.bool_value = true
        GROUP BY assessments.patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_fever_or_fever_reducer_at = t.latest_fever_or_fever_reducer_at
    SQL

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

    # populate :negative_lab_count
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, COUNT(*) AS negative_lab_count
        FROM laboratories
        WHERE result = 'negative'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.negative_lab_count = t.negative_lab_count
    SQL

    # populate :latest_transfer_at and :latest_transfer_from
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT transfers.patient_id, transfers.from_jurisdiction_id AS transferred_from, latest_transfers.transferred_at
        FROM transfers
        INNER JOIN (
          SELECT patient_id, MAX(created_at) AS transferred_at
          FROM transfers
          GROUP BY patient_id
        ) latest_transfers ON transfers.patient_id = latest_transfers.patient_id
          AND transfers.created_at = latest_transfers.transferred_at
      ) t ON patients.id = t.patient_id
      SET patients.latest_transfer_from = t.transferred_from, patients.latest_transfer_at = t.transferred_at
    SQL
  end

  def down
    remove_column :patients, :latest_assessment_at, :datetime
    remove_column :patients, :latest_fever_or_fever_reducer_at
    remove_column :patients, :latest_positive_lab_at, :date
    remove_column :patients, :negative_lab_count, :integer
    remove_column :patients, :latest_transfer_at, :datetime
    remove_column :patients, :latest_transfer_from, :integer
  end
end
