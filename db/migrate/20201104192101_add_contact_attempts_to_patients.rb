class AddContactAttemptsToPatients < ActiveRecord::Migration[6.0]
  def up
    add_column :patients, :contact_attempts, :integer, default: 0

    # populate :contact_attempts
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, COUNT(*) AS contact_attempts
        FROM histories
        WHERE history_type = 'Contact Attempt'
        AND created_by <> 'Sara Alert System'
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.contact_attempts = t.contact_attempts
      WHERE purged = FALSE
    SQL
  end

  def down
    remove_column :patients, :contact_attempts, :integer
  end
end
