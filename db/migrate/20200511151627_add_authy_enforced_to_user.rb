class AddAuthyEnforcedToUser < ActiveRecord::Migration[6.0]
  def self.up
    change_table :users do |t|
      t.boolean :authy_enforced, :default => true
    end
  end

  def self.down
    change_table :users do |t|
      t.remove :authy_enforced
    end
  end
end
