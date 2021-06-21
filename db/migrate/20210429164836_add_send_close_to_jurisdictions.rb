class AddSendCloseToJurisdictions < ActiveRecord::Migration[6.1]
  def change
    add_column :jurisdictions, :send_close, :boolean, default: false
  end
end
