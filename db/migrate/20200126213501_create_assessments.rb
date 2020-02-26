class CreateAssessments < ActiveRecord::Migration[6.0]
  def change
    create_table :assessments do |t|
      t.timestamps
      t.references :patient, index: true

      t.boolean :symptomatic
  
      t.string :who_reported, default: 'Monitoree'

      #t.boolean :felt_feverish
      # t.boolean :cough
      #t.boolean :sore_throat
      # t.boolean :difficulty_breathing
      #t.boolean :muscle_aches
      #t.boolean :headache
      #t.boolean :abdominal_discomfort
      #t.boolean :vomiting
      #t.boolean :diarrhea
    end
  end
end
