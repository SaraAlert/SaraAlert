class CreateUserExportPresets < ActiveRecord::Migration[6.0]
  def change
    create_table :user_export_presets do |t|
      t.references :user, index: true

      t.string :name, null: false
      t.json :config, null: false

      t.timestamps
    end
  end
end
