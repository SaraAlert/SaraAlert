class CreatePeople < ActiveRecord::Migration[6.0]
  def change
    create_table :people do |t|
      t.timestamps
      t.string :first_name
      t.string :last_name
      t.string :address
      t.string :city
      t.string :state
      t.string :email
      t.string :phone
      t.boolean :primary
      # TODO: Probably want a foreign key
      t.references :group, index: true
    end
  end
end
