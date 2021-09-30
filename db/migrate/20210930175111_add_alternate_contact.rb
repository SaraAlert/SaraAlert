class AddAlternateContact < ActiveRecord::Migration[6.1]
  def change
    add_column :patients, :contact_type, :string, default: 'Unknown'
    add_column :patients, :contact_name, :string
    add_column :patients, :alternate_contact_type, :string
    add_column :patients, :alternate_contact_name, :string
  end
end
