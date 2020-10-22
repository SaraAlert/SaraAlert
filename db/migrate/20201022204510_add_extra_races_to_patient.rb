class AddExtraRacesToPatient < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :unknown, :boolean
    add_column :patients, :other, :boolean
    add_column :patients, :refused_to_answer, :boolean

    add_column :patients, :races, :string, array: true, default: [].to_yaml
  end
end
