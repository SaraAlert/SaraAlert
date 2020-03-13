class CreateTransfers < ActiveRecord::Migration[6.0]
  def change
    create_table :transfers do |t|
      t.references :patient, index: true

      t.integer :to_jurisdiction_id, index: true
      t.integer :from_jurisdiction_id, index: true
      t.integer :who_id, index: true

      t.timestamps
    end
  end
end
