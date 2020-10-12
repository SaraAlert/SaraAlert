class CreateUserFilters < ActiveRecord::Migration[6.0]
  def change
    create_table :user_filters do |t|
      t.references :user, index: true

      t.json :contents, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
