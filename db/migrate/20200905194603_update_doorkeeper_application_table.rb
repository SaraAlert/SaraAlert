class UpdateDoorkeeperApplicationTable < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_applications, :public_key_set, :text
    add_column :oauth_applications, :jurisdiction_id, :integer
  end
end
