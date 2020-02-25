class CreateRoles < ActiveRecord::Migration[6.0]
  ROLES = [:admin, :enroller, :public_health, :public_health_enroller, :analyst]
  def up
    ROLES.each { |name| Role.create! name: name }
  end
  def down
    Role.where(name: ROLES).destroy_all
  end
end
