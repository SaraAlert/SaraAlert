class AddRoleToUsers < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :role, :string, null: false, default: 'none'
    User.includes(:roles).all.each do |user|
      user.update(role: user.roles.first&.name || 'none')
    end
  end

  def down
    remove_column :users, :role
  end
end
