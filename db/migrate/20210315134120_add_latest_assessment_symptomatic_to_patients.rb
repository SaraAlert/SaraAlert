class AddLatestAssessmentSymptomaticToPatients < ActiveRecord::Migration[6.1]
  def up
    add_column :patients, :latest_assessment_symptomatic, :boolean, default: false

    # populate :latest_assessment_symptomatic
    execute <<-SQL.squish
      UPDATE patients
      JOIN (
        SELECT assessments.patient_id
        FROM assessments
        JOIN (
          SELECT patient_id, MAX(created_at) AS latest_assessment_at
          FROM assessments
          GROUP BY patient_id
        ) latest_assessments
        ON assessments.patient_id = latest_assessments.patient_id
        AND assessments.created_at = latest_assessments.latest_assessment_at
        WHERE assessments.symptomatic = TRUE
      ) latest_symptomatic_assessments
      ON patients.id = latest_symptomatic_assessments.patient_id
      SET patients.latest_assessment_symptomatic = TRUE
    SQL
  end

  def down
    remove_column :patients, :latest_assessment_symptomatic, :boolean
  end
end
