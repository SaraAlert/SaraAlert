class CreateHistories < ActiveRecord::Migration[6.0]
  def change
    create_table :histories do |t|
      t.references :patient, index: true

      t.text :comment
      t.string :created_by
      t.string :history_type

      t.timestamps
    end
  end
end
