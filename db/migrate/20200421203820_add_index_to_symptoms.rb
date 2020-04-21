class AddIndexToSymptoms < ActiveRecord::Migration[6.0]
  def change
    add_index :symptoms, :condition_id
  end
end
