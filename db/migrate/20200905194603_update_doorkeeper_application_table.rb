class UpdateDoorkeeperApplicationTable < ActiveRecord::Migration[6.0]
  def change
    add_column :oauth_applications, :public_key_set, :json
    add_column :oauth_applications, :jurisdiction_id, :integer
    add_column :oauth_applications, :user_id, :bigint
  end
end
