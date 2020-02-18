class Jurisdiction < ApplicationRecord
  has_ancestry
  # Immediate patients are those just in this jurisdiction
  has_many :immediate_patients, class_name: 'Patient'
  # All patients are all those in this or descendent jurisdictions
  def all_patients
    Patient.where(jurisdiction_id: subtree_ids)
  end

  def jurisdiction_path_string
    path&.map(&:name).join(', ')
  end

end
