class CreateJurisdictions < ActiveRecord::Migration[6.0]
  def change
    create_table :jurisdictions do |t|
      t.timestamps
      t.string :name
      t.string :ancestry, index: true
    end
  end
end
