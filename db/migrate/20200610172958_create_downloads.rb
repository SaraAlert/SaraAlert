class CreateDownloads < ActiveRecord::Migration[6.0]
  def change
    create_table :downloads do |t|
      t.references :user, index: true

      t.binary :contents, limit: 100.megabytes, null: false
      t.string :lookup, null: false
      t.string :filename, null: false
      t.string :export_type, null: false

      t.timestamps
    end
  end
end
