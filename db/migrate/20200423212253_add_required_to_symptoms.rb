class AddRequiredToSymptoms < ActiveRecord::Migration[6.0]
  def change
    add_column :symptoms, :required, :boolean, default: true
  end
end
