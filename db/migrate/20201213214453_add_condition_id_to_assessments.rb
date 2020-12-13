class AddConditionIdToAssessments < ActiveRecord::Migration[6.0]
  def up
    add_column :assessments, :reported_condition_id, :bigint, null: false

    # populate :reported_condition_id
    execute <<-SQL.squish
      UPDATE
        assessments a,
        conditions c
      SET
        a.reported_condition_id = c.id
      WHERE
        c.type = 'ReportedCondition'
        AND
        a.id = c.assessment_id
    SQL

    # Find assessments without reported condition after with:
    # Assessment.where(reported_condition_id: 0)
  end

  def down
    remove_column :assessments, :reported_condition_id, :bigint
  end
end
