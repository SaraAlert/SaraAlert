class AddChainIndexToAssessments < ActiveRecord::Migration[6.0]
  def change
    add_index :assessments, [:created_at], name: 'assessments_index_chain_1'
    add_index :assessments, [:symptomatic, :patient_id, :created_at], name: 'assessments_index_chain_2'
    add_index :assessments, [:patient_id, :created_at], name: 'assessments_index_chain_3'
    remove_index :assessments, name: 'index_assessments_on_patient_id'
  end
end
