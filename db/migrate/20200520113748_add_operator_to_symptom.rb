class AddOperatorToSymptom < ActiveRecord::Migration[6.0]
  def self.up
    change_table :symptoms do |t|
      t.string :threshold_operator, :default => 'Less Than'
    end
  end

  def self.down
    change_table :symptoms do |t|
      t.remove :threshold_operator
    end
  end
end
