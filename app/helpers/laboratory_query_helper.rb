# frozen_string_literal: true

# Helper methods for filtering through laboratories
module LaboratoryQueryHelper
  def laboratories_by_query(patients_identifiers)
    Laboratory.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end

  def extract_laboratories_details(patients_identifiers, laboratories, fields)
    laboratories_details = []
    laboratories.each do |laboratory|
      laboratory_details = {}
      laboratory_details[:patient_id] = laboratory[:patient_id] || '' if fields.include?(:patient_id)
      %i[user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss].each do |identifier|
        laboratory_details[identifier] = patients_identifiers[laboratory[:patient_id]][identifier] || '' if fields.include?(identifier)
      end
      laboratory_details[:id] = laboratory[:id] || '' if fields.include?(:id)
      laboratory_details[:lab_type] = laboratory[:lab_type] || '' if fields.include?(:lab_type)
      laboratory_details[:specimen_collection] = laboratory[:specimen_collection]&.strftime('%F') || '' if fields.include?(:specimen_collection)
      laboratory_details[:report] = laboratory[:report]&.strftime('%F') || '' if fields.include?(:report)
      laboratory_details[:result] = laboratory[:result] || '' if fields.include?(:result)
      laboratory_details[:created_at] = laboratory[:created_at]&.strftime('%F') || '' if fields.include?(:created_at)
      laboratory_details[:updated_at] = laboratory[:updated_at]&.strftime('%F') || '' if fields.include?(:updated_at)
      laboratories_details << laboratory_details
    end
  end
end
