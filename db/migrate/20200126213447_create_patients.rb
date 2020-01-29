class CreatePatients < ActiveRecord::Migration[6.0]
  def change
    # TODO: reconsider the lack of a group table (allows better separation of PII in the patients table)
    # TODO: consider generalizing the labels for names, address, etc. e.g. name1, name2, name3 (helps localization)
    create_table :patients do |t|
      t.timestamps
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :suffix
      t.integer :dob_day
      t.integer :dob_month
      t.integer :dob_year
      t.integer :age
      t.string :sex
      t.boolean :white
      t.boolean :black_or_african_american
      t.boolean :american_indian_or_alaska_native
      t.boolean :asian
      t.boolean :native_hawaiian_or_other_pacific_islander
      t.boolean :ethnicity
      t.string :primary_language
      t.string :secondary_language
      t.boolean :interpretation_required
      t.string :residence_line_1
      t.string :residence_line_2
      t.string :residence_city
      t.string :residence_county
      t.string :residence_state
      t.string :residence_country
      t.string :email
      t.string :phone
      t.string :primary_phone
      t.string :secondary_phone
      t.integer :responder_id, index: true
      t.integer :creator_id, index: true
      t.string :submission_token, index: true
    end
  end
end
