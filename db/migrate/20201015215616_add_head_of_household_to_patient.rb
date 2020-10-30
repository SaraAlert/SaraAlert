class AddHeadOfHouseholdToPatient < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :head_of_household, :boolean, null: true
  end
end
