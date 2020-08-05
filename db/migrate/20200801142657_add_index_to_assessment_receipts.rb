class AddIndexToAssessmentReceipts < ActiveRecord::Migration[6.0]
  def change
    add_index :assessment_receipts, :submission_token
  end
end
