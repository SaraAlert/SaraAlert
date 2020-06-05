class AddApiEnabledToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :api_enabled, :boolean, default: false
  end
end
