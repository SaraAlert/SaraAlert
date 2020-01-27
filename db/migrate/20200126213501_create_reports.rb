class CreateReports < ActiveRecord::Migration[6.0]
  def change
    create_table :reports do |t|
      t.timestamps
      # TODO: For eventual performance we may want a statuses table
      t.string :status, index: true
      t.references :patient, index: true
    end
  end
end
