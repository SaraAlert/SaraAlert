class CreateStats < ActiveRecord::Migration[6.0]
  def change
    create_table :stats do |t|
      t.integer :jurisdiction_id, null: false
      t.json :contents, null: false
      t.string :tag, null: false

      t.timestamps
    end
  end
end
