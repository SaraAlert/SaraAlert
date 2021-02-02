class CloseContactUpdates < ActiveRecord::Migration[6.1]
  def change
    add_column :close_contacts, :last_date_of_exposure, :date
    add_column :close_contacts, :assigned_user, :integer

  end
end
