class AddLatestAssessmentSymptomaticToPatients < ActiveRecord::Migration[6.1]
  def up
    add_column :patients, :latest_assessment_symptomatic, :boolean, default: false

    # populate :latest_assessment_symptomatic
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, MAX(created_at)
        FROM assessments
        WHERE symptomatic = TRUE
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_assessment_symptomatic = TRUE
    SQL
  end

  def down
    remove_column :patients, :latest_assessment_symptomatic, :boolean
  end
end
