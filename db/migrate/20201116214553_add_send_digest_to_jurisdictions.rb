class AddSendDigestToJurisdictions < ActiveRecord::Migration[6.0]
  def change
    add_column :jurisdictions, :send_digest, :boolean, default: false
  end
end
