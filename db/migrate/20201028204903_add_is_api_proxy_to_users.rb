class AddIsApiProxyToUsers < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :is_api_proxy, :boolean, default: false
    # Update all existing API proxy users to have this field set to true
    User.where(id: OauthApplication.where.not(user_id: nil).pluck(:user_id)).update_all(is_api_proxy: true)
  end

  def down
    remove_column :users, :is_api_proxy
  end
end
