class AddInternationalTelephoneToPatients < ActiveRecord::Migration[6.1]
  def change
    add_column :patients, :international_telephone, :string
  end
end
