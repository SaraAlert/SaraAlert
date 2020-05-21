class AddOperatorToSymptom < ActiveRecord::Migration[6.0]
  def self.up
    change_table :symptoms do |t|
      t.string :threshold_operator, :default => 'Less Than'
      t.integer :group, :default => 1
    end
  end

  def self.down
    change_table :symptoms do |t|
      t.remove :threshold_operator
      t.remove :group
    end
  end
end
