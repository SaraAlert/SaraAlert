class AddAlternateContact < ActiveRecord::Migration[6.1]
  def change
    add_column :patients, :contact_type, :string, limit: 200, default: 'Unknown'
    add_column :patients, :contact_name, :string, limit: 200
    add_column :patients, :alternate_contact_type, :string, limit: 200
    add_column :patients, :alternate_contact_name, :string, limit: 200
    add_column :patients, :alternate_preferred_contact_method, :string, limit: 200
    add_column :patients, :alternate_preferred_contact_time, :string, limit: 200
    add_column :patients, :alternate_primary_telephone, :string, limit: 200
    add_column :patients, :alternate_primary_telephone_type, :string, limit: 200
    add_column :patients, :alternate_secondary_telephone, :string, limit: 200
    add_column :patients, :alternate_secondary_telephone_type, :string, limit: 200
    add_column :patients, :alternate_international_telephone, :string, limit: 200
    add_column :patients, :alternate_email, :string, limit: 200
  end
end
