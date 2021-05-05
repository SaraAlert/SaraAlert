class AddAsymptomaticToPatients < ActiveRecord::Migration[6.1]
  def change
    add_column :patients, :asymptomatic, :boolean
  end
end
