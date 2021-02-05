class CreateVaccines < ActiveRecord::Migration[6.1]
  def change
    create_table :vaccines do |t|
      t.references :patient, index: true

      t.string :group_name
      t.string :product_name
      t.date :administration_date
      # String because "Unknown" is a valid option"
      t.string :dose_number
      t.text :notes
      
      t.timestamps
    end
  end
end
