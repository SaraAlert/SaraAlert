class AddIndexToConditions < ActiveRecord::Migration[6.0]
  def change
    add_index :conditions, :assessment_id
  end
end
