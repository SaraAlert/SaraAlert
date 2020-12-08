# frozen_string_literal: true

# Helper methods for filtering through transfers
module TransferQueryHelper
  def transfers_by_query(patients_identifiers)
    Transfer.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end

  def extract_transfers_details(patients_identifiers, transfers, fields)
    jurisdiction_ids = [transfers.map(&:from_jurisdiction_id), transfers.map(&:to_jurisdiction_id)].flatten.uniq
    jurisdiction_paths = Hash[Jurisdiction.find(jurisdiction_ids).pluck(:id, :path).map { |id, path| [id, path] }]
    user_emails = Hash[User.find(transfers.map(&:who_id).uniq).pluck(:id, :email).map { |id, email| [id, email] }]
    transfers_details = []
    transfers.each do |transfer|
      transfer_details = {}
      transfer_details[:patient_id] = transfer[:patient_id] || '' if fields.include?(:patient_id)
      %i[user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss].each do |identifier|
        transfer_details[identifier] = patients_identifiers[transfer[:patient_id]][identifier] || '' if fields.include?(identifier)
      end
      transfer_details[:id] = transfer[:id] || '' if fields.include?(:id)
      transfer_details[:who] = user_emails[transfer[:who_id]] || '' if fields.include?(:who)
      transfer_details[:from_jurisdiction] = jurisdiction_paths[transfer[:from_jurisdiction_id]] || '' if fields.include?(:from_jurisdiction)
      transfer_details[:to_jurisdiction] = jurisdiction_paths[transfer[:to_jurisdiction_id]] || '' if fields.include?(:to_jurisdiction)
      transfer_details[:created_at] = transfer[:created_at]&.strftime('%F') || '' if fields.include?(:created_at)
      transfer_details[:updated_at] = transfer[:updated_at]&.strftime('%F') || '' if fields.include?(:updated_at)
      transfers_details << transfer_details
    end
    transfers_details
  end
end
