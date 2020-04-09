class AddSourceOfReportSpecifyToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :source_of_report_specify, :string
  end
end
