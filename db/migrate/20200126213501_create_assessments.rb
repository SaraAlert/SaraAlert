class CreateAssessments < ActiveRecord::Migration[6.0]
  def change
    create_table :assessments do |t|
      t.timestamps
      # TODO: For eventual performance we may want a status table
      t.string :status, index: true
      t.references :patient, index: true
    end
  end
end
