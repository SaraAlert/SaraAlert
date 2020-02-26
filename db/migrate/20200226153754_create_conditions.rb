class CreateConditions < ActiveRecord::Migration[6.0]
  def change
    create_table :conditions do |t|
      t.timestamps
      t.integer :jurisdiction_id
      t.integer :assessment_id
    end
  end
end
