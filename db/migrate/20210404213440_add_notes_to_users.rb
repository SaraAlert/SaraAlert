class AddNotesToUsers < ActiveRecord::Migration[6.1]
    def up
      add_column :users, :notes, :text
    end
  
    def down
      remove_column :users, :notes
    end
  end
  