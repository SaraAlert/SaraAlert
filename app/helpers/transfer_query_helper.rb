# frozen_string_literal: true

# Helper methods for filtering through transfers
module TransferQueryHelper
  def validate_transfers_query(unsanitized_query)
    # Only allow permitted params
    unsanitized_query.permit
  end

  # rubocop:disable Lint/UnusedMethodArgument
  def transfers_by_query(patient_ids, query)
    Transfer.where(patient_id: patient_ids).order(:patient_id)
  end
  # rubocop:enable Lint/UnusedMethodArgument
end

# Exception used for reporting validation errors
class InvalidQueryError < StandardError
  def initialize(field, value)
    super("Invalid Query (#{field}): #{value}")
  end
end
