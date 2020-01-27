class CreatePatients < ActiveRecord::Migration[6.0]
  def change
    # TODO: reconsider the lack of a group table (allows better separation of PII in the patients table)
    # TODO: consider generalizing the labels for names, address, etc. e.g. name1, name2, name3 (helps localization)
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
      t.integer :creator_id, index: true
    end
  end
end
