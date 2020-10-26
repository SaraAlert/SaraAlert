class RemoveOldRacesFromPatient < ActiveRecord::Migration[6.0]
  def change
    remove_column :patients, :white, :boolean
    remove_column :patients, :black_or_african_american, :boolean
    remove_column :patients, :american_indian_or_alaska_native, :boolean
    remove_column :patients, :asian, :boolean
    remove_column :patients, :native_hawaiian_or_other_pacific_islander, :boolean
    remove_column :patients, :unknown, :boolean
    remove_column :patients, :other, :boolean
    remove_column :patients, :refused_to_answer, :boolean
  end
end
