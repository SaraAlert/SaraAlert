class CreateRoles < ActiveRecord::Migration[6.0]
  ROLES = [:admin, :enroller, :monitor, :analyst]
  def up
    ROLES.each { |name| Role.create! name: name }
  end
  def down
    Role.where(name: ROLES).destroy_all
  end
end
