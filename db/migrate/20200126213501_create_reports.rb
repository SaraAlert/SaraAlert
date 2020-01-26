class CreateReports < ActiveRecord::Migration[6.0]
  def change
    create_table :reports do |t|
      t.timestamps
      # TODO: For eventual performance we may want a states table
      t.string :state, index: true
      # TODO: Probably want a foreign key
      t.references :group, index: true
    end
  end
end
