class AddCustomMessagesToJurisdictions < ActiveRecord::Migration[6.1]
  def change
    add_column :jurisdictions, :custom_messages, :json
  end
end
