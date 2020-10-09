class CreateJwtIdentifiers < ActiveRecord::Migration[6.0]
  def change
    create_table :jwt_identifiers do |t|
      t.string :value
      t.datetime :expiration_date
      t.references :application, null: false, foreign_key: {to_table: :oauth_applications}
      t.timestamps
    end
  end
end
