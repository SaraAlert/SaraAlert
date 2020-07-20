class AddIdentityToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :gender_identity, :string
    add_column :patients, :sexual_orientation, :string
  end
end
