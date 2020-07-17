class AddContactInfoToJurisdictions < ActiveRecord::Migration[6.0]
  def change
    add_column :jurisdictions, :phone, :string
    add_column :jurisdictions, :email, :string
    add_column :jurisdictions, :webpage, :string
    add_column :jurisdictions, :message, :string
  end
end
