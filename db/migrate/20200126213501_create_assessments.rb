class CreateAssessments < ActiveRecord::Migration[6.0]
  def change
    create_table :assessments do |t|
      t.timestamps
      # TODO: For eventual performance we may want a status table
      t.string :status, index: true
      t.references :patient, index: true
      t.string :temperature
      t.boolean :felt_feverish
      t.boolean :cough
      t.boolean :sore_throat
      t.boolean :difficulty_breathing
      t.boolean :muscle_aches
      t.boolean :headache
      t.boolean :abdominal_discomfort
      t.boolean :vomiting
      t.boolean :diarrhea
    end
  end
end
