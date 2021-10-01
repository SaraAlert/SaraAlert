class AddAlternateContact < ActiveRecord::Migration[6.1]
  def change
    add_column :patients, :contact_type, :string, default: 'Unknown'
    add_column :patients, :contact_name, :string
    add_column :patients, :alternate_contact_type, :string
    add_column :patients, :alternate_contact_name, :string
    add_column :patients, :alternate_preferred_contact_method, :string
    add_column :patients, :alternate_preferred_contact_time, :string
    add_column :patients, :alternate_primary_telephone, :string
    add_column :patients, :alternate_primary_telephone_type, :string
    add_column :patients, :alternate_secondary_telephone, :string
    # add_column :patients, :alternate_secondary_telephone_type, :string
    # add_column :patients, :alternate_international_telephone, :string
    add_column :patients, :alternate_email, :string
  end
end
