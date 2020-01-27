class CreatePatients < ActiveRecord::Migration[6.0]
  def change
    create_table :patients do |t|
      t.timestamps
      t.string :first_name
      t.string :last_name
      t.string :residence_line_1
      t.string :residence_line_2
      t.string :residence_city
      t.string :residence_county
      t.string :residence_state
      t.string :email
      t.string :phone
      t.integer :responder_id, index: true
    end
  end
end
