class AddRoleToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :role, :string, null: false, default: ''
    User.includes(:roles).all.each do |user|
      user.update(role: user.roles.first.name)
    end
  end
end
