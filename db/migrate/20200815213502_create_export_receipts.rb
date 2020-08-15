class CreateExportReceipts < ActiveRecord::Migration[6.0]
  def change
    create_table :export_receipts do |t|
      t.timestamps
      t.references :user, index: true
      t.string :export_type, null: false
    end
  end
end
