# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      ## Password recovery needs to be handled by an admin
      #t.string   :reset_password_token
      #t.datetime :reset_password_sent_at

      ## Rememberable
      ## Password should be entered every login
      #t.datetime :remember_created_at

      ## Trackable
      ## User access should be tracked
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      # Require the user to change their password on first login (used on account setup)
      t.boolean :force_password_change

      # Each user is associated with one jurisdiction that they have access to (along with sub-jurisdictions)
      t.integer :jurisdiction_id, index: true

      t.datetime :password_changed_at

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :password_changed_at
    # add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
  end
end
