# frozen_string_literal: true

# Helper methods for filtering through histories
module HistoryQueryHelper
  def histories_by_query(patients_identifiers)
    History.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end

  def extract_histories_details(patients_identifiers, histories, fields)
    histories_details = []
    histories.each do |history|
      history_details = {}
      history_details[:patient_id] = history[:patient_id] || '' if fields.include?(:patient_id)
      %i[user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss].each do |identifier|
        history_details[identifier] = patients_identifiers[history[:patient_id]][identifier] || '' if fields.include?(identifier)
      end
      history_details[:id] = history[:id] || '' if fields.include?(:id)
      history_details[:created_by] = history[:created_by] || '' if fields.include?(:created_by)
      history_details[:history_type] = history[:history_type] || '' if fields.include?(:history_type)
      history_details[:comment] = history[:comment] || '' if fields.include?(:comment)
      history_details[:created_at] = history[:created_at]&.strftime('%F') || '' if fields.include?(:created_at)
      history_details[:updated_at] = history[:updated_at]&.strftime('%F') || '' if fields.include?(:updated_at)
      histories_details << history_details
    end
    histories_details
  end
end
