class AddDiffContactAttemptsToPatients < ActiveRecord::Migration[6.0]
  def up
    add_column :patients, :contact_attempts, :integer, default: 0
    add_column :patients, :contact_attempts_successful, :integer, default: 0
    add_column :patients, :contact_attempts_unsuccessful, :integer, default: 0

    # populate :contact_attempts
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, COUNT(*) AS contact_attempts
        FROM histories
        WHERE history_type = 'Contact Attempt'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.contact_attempts = t.contact_attempts
      WHERE purged = FALSE
    SQL

    # populate :contact_attempts_unsuccessful
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, COUNT(*) AS contact_attempts_unsuccessful
        FROM histories
        WHERE history_type = 'Contact Attempt'
        AND comment LIKE '%unsuccessful%'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.contact_attempts_unsuccessful = t.contact_attempts_unsuccessful
      WHERE purged = FALSE
    SQL

    # populate :contact_attempts_successful
    execute <<-SQL.squish
      UPDATE patients
      SET patients.contact_attempts_successful =  patients.contact_attempts - patients.contact_attempts_unsuccessful
      WHERE purged = FALSE
    SQL
  end

  def down
    remove_column :patients, :contact_attempts, :integer
    remove_column :patients, :contact_attempts_successful, :integer
    remove_column :patients, :contact_attempts_unsuccessful, :integer
  end
end
