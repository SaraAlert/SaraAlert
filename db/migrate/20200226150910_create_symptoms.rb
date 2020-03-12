class CreateSymptoms < ActiveRecord::Migration[6.0]
  def change
    create_table :symptoms do |t|
      t.string :name
      t.string :label
      t.string :notes
      
      # Add fields for child-types of symptoms
      t.boolean :bool_value
      t.float   :float_value
      t.integer :int_value

      t.integer :condition_id
  
      # Store concrete type of symptom
      t.string :type
      t.timestamps
    end
  end
end
