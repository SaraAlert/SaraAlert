class AddManualLockReasonToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :manual_lock_reason, :string
  end
end
