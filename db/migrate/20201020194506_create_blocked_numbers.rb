class CreateBlockedNumbers < ActiveRecord::Migration[6.0]
  def change
    create_table :blocked_numbers do |t|
      t.string :phone_number, null: false
      t.index [:phone_number], name: "index_blocked_phone_number"
    end
  end
end