class CreateContactAttempts < ActiveRecord::Migration[6.0]
  def up
    create_table :contact_attempts do |t|
      t.references :patient, index: true
      t.references :user, index: true

      t.boolean :successful, index: true
      t.string :note

      t.timestamps
    end

    # mysql does not support full joins
    execute <<-SQL.squish
      INSERT INTO contact_attempts (patient_id, user_id, successful, note, created_at, updated_at)
      SELECT histories.patient_id as patient_id,
            users.id as user_id,
            histories.comment NOT LIKE '%unsuccessful%' as successful,
            SUBSTRING_INDEX(histories.comment, 'uccessful contact attempt. Note: ', -1) as comment,
            histories.created_at as created_at,
            histories.updated_at as updated_at
      FROM histories
      LEFT JOIN users
      ON histories.created_by = users.email
      WHERE history_type = 'Contact Attempt'
      UNION
      SELECT histories.patient_id as patient_id,
            users.id as user_id,
            histories.comment NOT LIKE '%unsuccessful%' as successful,
            SUBSTRING_INDEX(histories.comment, 'uccessful contact attempt. Note: ', -1) as comment,
            histories.created_at as created_at,
            histories.updated_at as updated_at
      FROM users
      RIGHT JOIN histories
      ON histories.created_by = users.email
      WHERE history_type = 'Contact Attempt'
    SQL
  end

  def down
    drop_table :contact_attempts
  end
end
