class AddPathToJurisdiction < ActiveRecord::Migration[6.0]
  def up
    add_column :jurisdictions, :path, :string
    Jurisdiction.all.each do |jurisdiction|
      jurisdiction.update(path: jurisdiction.path&.map(&:name)&.join(', '))
    end
  end
end
