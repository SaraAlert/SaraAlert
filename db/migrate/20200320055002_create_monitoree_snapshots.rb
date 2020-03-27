class CreateMonitoreeSnapshots < ActiveRecord::Migration[6.0]
  def change
    create_table :monitoree_snapshots do |t|
      t.references :analytic, index: true

      t.string :time_frame
      t.integer :new_enrollments
      t.integer :transferred_in
      t.integer :closed
      t.integer :transferred_out

      t.integer :referral_for_medical_evaluation
      t.integer :document_completed_medical_evaluation
      t.integer :document_medical_evaluation_summary_and_plan
      t.integer :referral_for_public_health_test
      t.integer :public_health_test_specimen_received_by_lab_results_pending
      t.integer :results_of_public_health_test_positive
      t.integer :results_of_public_health_test_negative

      t.timestamps
    end
  end
end
