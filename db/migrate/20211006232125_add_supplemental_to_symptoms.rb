class AddSupplementalToSymptoms < ActiveRecord::Migration[6.1]
  def change
    add_column :symptoms, :supplemental, :boolean, default: false
  end
end
