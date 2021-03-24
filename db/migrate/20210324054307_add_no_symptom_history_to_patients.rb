class AddNoSymptomHistoryToPatients < ActiveRecord::Migration[6.1]
  def change
    add_column :patients, :no_symptom_history, :boolean
  end
end
