class CreateMonitoreeMaps < ActiveRecord::Migration[6.0]
  def change
    create_table :monitoree_maps do |t|
      t.references :analytic, index: true

      t.string :level
      t.string :workflow
      t.string :state
      t.string :county
      t.integer :total

      t.timestamps
    end
  end
end
