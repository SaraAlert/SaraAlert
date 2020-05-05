class ChangeDefaultvalueForAuthyEnabled < ActiveRecord::Migration[6.0]
  def change
    change_column_default :users, :authy_enabled, from: true, to: false
  end
end
