class CreateAssessmentReceipts < ActiveRecord::Migration[6.0]
  def change
    create_table :assessment_receipts do |t|
      t.timestamps

      t.string :submission_token
    end
  end
end
