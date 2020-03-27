class CreateMonitoreeCounts < ActiveRecord::Migration[6.0]
  def change
    create_table :monitoree_counts do |t|
      t.references :analytic, index: true

      t.boolean :active_monitoring
      t.string :category_type
      t.string :category
      t.string :risk_level
      t.integer :total
      
      t.timestamps
    end
  end
end
