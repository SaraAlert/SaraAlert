class AddChainIndexToPatientsTwo < ActiveRecord::Migration[6.0]
  def change
    add_index :patients, [:primary_telephone, :responder_id, :id, :jurisdiction_id], name: 'patients_index_chain_two_1'
    add_index :patients, [:email, :responder_id, :id, :jurisdiction_id], name: 'patients_index_chain_two_2'
  end
end
