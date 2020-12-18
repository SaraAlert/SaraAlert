class CreateContactAttempts < ActiveRecord::Migration[6.0]
  def up
    remove_column :patients, :contact_attempts, :integer

    create_table :contact_attempts do |t|
      t.references :patient, index: true
      t.references :user, index: true

      t.boolean :successful, index: true
      t.text :note

      t.timestamps
    end

    # mysql does not support full joins
    execute <<-SQL.squish
      INSERT INTO contact_attempts (patient_id, user_id, successful, note, created_at, updated_at)
      SELECT histories.patient_id as patient_id,
             users.id as user_id,
             histories.comment NOT LIKE '%unsuccessful contact attempt%' as successful,
             SUBSTRING_INDEX(histories.comment, 'uccessful contact attempt. Note: ', -1) as comment,
             histories.created_at as created_at,
             histories.updated_at as updated_at
      FROM histories
      LEFT JOIN users
      ON histories.created_by = users.email
      WHERE history_type = 'Contact Attempt'
      AND created_by <> 'Sara Alert System'
      UNION
      SELECT histories.patient_id as patient_id,
             users.id as user_id,
             histories.comment NOT LIKE '%unsuccessful contact attempt%' as successful,
             SUBSTRING_INDEX(histories.comment, 'uccessful contact attempt. Note: ', -1) as comment,
             histories.created_at as created_at,
             histories.updated_at as updated_at
      FROM users
      RIGHT JOIN histories
      ON histories.created_by = users.email
      WHERE history_type = 'Contact Attempt'
      AND created_by <> 'Sara Alert System'
    SQL
  end

  def down
    drop_table :contact_attempts

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
end
