class CreateAssessments < ActiveRecord::Migration[6.0]
  def change
    create_table :assessments do |t|
      t.timestamps
      t.references :patient, index: true

      t.boolean :symptomatic

      t.string :who_reported, default: 'Monitoree'
    end
  end
end
