class ChangeIdentifiersToBeBinaryInPatientsAndJurisdictions < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
      ALTER TABLE patients MODIFY `submission_token` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin
    SQL

    execute <<-SQL
      ALTER TABLE patient_lookups MODIFY `new_submission_token` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin
    SQL

    execute <<-SQL
      ALTER TABLE jurisdictions MODIFY `unique_identifier` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin
    SQL

    execute <<-SQL
      ALTER TABLE jurisdiction_lookups MODIFY `new_unique_identifier` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_bin
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE patients MODIFY `submission_token` VARCHAR(255) CHARACTER SET utf8
    SQL

    execute <<-SQL
      ALTER TABLE patient_lookups MODIFY `new_submission_token` VARCHAR(255) CHARACTER SET utf8
    SQL

    execute <<-SQL
      ALTER TABLE jurisdictions MODIFY `unique_identifier` VARCHAR(255) CHARACTER SET utf8
    SQL

    execute <<-SQL
      ALTER TABLE jurisdiction_lookups MODIFY `new_unique_identifier` VARCHAR(255) CHARACTER SET utf8
    SQL
  end
end
