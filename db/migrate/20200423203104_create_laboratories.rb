class CreateLaboratories < ActiveRecord::Migration[6.0]
  def change
    create_table :laboratories do |t|
      t.references :patient, index: true

      t.string :lab_type
      t.date :specimen_collection
      t.date :report
      t.string :result

      t.timestamps
    end
  end
end
