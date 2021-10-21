class AddReportedAtToAssessments < ActiveRecord::Migration[6.1]
  def change
    ActiveRecord::Base.record_timestamps = false

    add_column :assessments, :reported_at, :datetime, precision: 6, index: true

    up_only do
      execute 'update assessments set reported_at=created_at'
    end

    ActiveRecord::Base.record_timestamps = true
  end
end
