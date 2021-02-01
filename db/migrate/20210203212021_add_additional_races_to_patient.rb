class AddAdditionalRacesToPatient < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :race_other, :boolean
    add_column :patients, :race_unknown, :boolean
    add_column :patients, :race_refused_to_answer, :boolean
  end
end
