class AddSupplementalToSymptoms < ActiveRecord::Migration[6.1]
  def change
    add_column :symptoms, :supplemental, :boolean, default: false
    Symptom.where(name: 'used-a-fever-reducer').update_all(supplemental: true)
  end
end
