class CreateVaccine < ActiveRecord::Migration[6.0]
  def change
    create_table :vaccines do |t|
      t.references :patient, index: true

      t.boolean :vaccinated
      t.date :first_vac_date
      t.date :second_vac_date

      t.timestamps
    end
  end
end
