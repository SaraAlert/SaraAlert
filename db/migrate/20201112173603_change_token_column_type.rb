class ChangeTokenColumnType < ActiveRecord::Migration[6.0]
  def up
    change_column :patients, :submission_token, :binary, limit: 255
    change_column :patient_lookups, :new_submission_token, :binary, limit: 255
    change_column :jurisdictions, :unique_identifier, :binary, limit: 255
    change_column :jurisdiction_lookups, :new_unique_identifier, :binary, limit: 255
  end

  def down
    change_column :patients, :submission_token, :string
    change_column :patient_lookups, :new_submission_token, :string
    change_column :jurisdictions, :unique_identifier, :string
    change_column :jurisdiction_lookups, :new_unique_identifier, :string
  end
end