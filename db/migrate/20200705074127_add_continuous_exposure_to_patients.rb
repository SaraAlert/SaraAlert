class AddContinuousExposureToPatients < ActiveRecord::Migration[6.0]
  def change
    add_column :patients, :continuous_exposure, :boolean, default: false
  end
end
