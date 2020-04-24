class AddCaseStatusToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :case_status, :string
  end
end
