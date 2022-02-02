class AddLastActivityAtToUser < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false

    add_column :users, :last_activity_at, :datetime

    up_only do
      execute 'update users set last_activity_at=current_sign_in_at'
    end

    ActiveRecord::Base.record_timestamps = true

    add_index :users, :last_activity_at
  end
end
