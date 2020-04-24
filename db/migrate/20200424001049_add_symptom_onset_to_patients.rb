class AddSymptomOnsetToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :symptom_onset, :date
  end
end
