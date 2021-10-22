class AddReportedAtToAssessments < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false

    add_column :assessments, :reported_at, :datetime, precision: 6
    add_index :assessments, :reported_at

    up_only do
      execute 'update assessments set reported_at=created_at'
    end

    ActiveRecord::Base.record_timestamps = true
  end
end
