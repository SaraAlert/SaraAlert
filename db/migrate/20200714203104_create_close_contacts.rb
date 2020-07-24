class CreateCloseContacts < ActiveRecord::Migration[6.0]
  def change
    create_table :close_contacts do |t|
      t.references :patient, index: true

      t.string :first_name
      t.string :last_name
      t.string :primary_telephone
      t.string :email
      t.text :notes
      t.integer :enrolled_id
      t.integer :contact_attempts

      t.timestamps
    end
  end
end
