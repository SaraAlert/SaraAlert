class UpdatePatientsLatestAssessmentAtByAssessmentReportedAt < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up { populate_latest_assessment_fields(:reported_at) }
      dir.down { populate_latest_assessment_fields(:created_at) }
    end
  end

  def populate_latest_assessment_fields(field)
    # reset :latest_assessment_at and :latest_assessment_symptomatic to NULL
    execute <<-SQL.squish
      UPDATE patients
      SET patients.latest_assessment_at = NULL, patients.latest_assessment_symptomatic = NULL
      WHERE patients.purged = FALSE
    SQL

    # populate :latest_assessment_at
    execute <<-SQL.squish
      UPDATE patients
      INNER JOIN (
        SELECT patient_id, MAX(#{field}) AS latest_assessment_at
        FROM assessments
        WHERE created_at <> reported_at
        GROUP BY patient_id
      ) t ON patients.id = t.patient_id
      SET patients.latest_assessment_at = t.latest_assessment_at
      WHERE patients.purged = FALSE
    SQL

    # populate :latest_assessment_symptomatic
    execute <<-SQL.squish
      UPDATE patients
      JOIN (
        SELECT assessments.patient_id
        FROM assessments
        JOIN (
          SELECT patient_id, MAX(#{field}) AS latest_assessment_at
          FROM assessments
          WHERE created_at <> reported_at
          GROUP BY patient_id
        ) latest_assessments
        ON assessments.patient_id = latest_assessments.patient_id
        AND assessments.#{field} = latest_assessments.latest_assessment_at
        WHERE assessments.symptomatic = TRUE
      ) latest_symptomatic_assessments
      ON patients.id = latest_symptomatic_assessments.patient_id
      SET patients.latest_assessment_symptomatic = TRUE
      WHERE patients.purged = FALSE
    SQL
  end
end
