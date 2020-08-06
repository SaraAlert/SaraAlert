class AddUserDefinedSymptomOnset < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :user_defined_symptom_onset, :boolean
  end
end
