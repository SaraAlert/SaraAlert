# frozen_string_literal: true

# Helper methods for filtering through assessments
module AssessmentQueryHelper
  def validate_assessments_query(unsanitized_query)
    # Only allow permitted params
    unsanitized_query.permit
  end

  # rubocop:disable Lint/UnusedMethodArgument
  def assessments_by_query(patient_ids, query)
    Assessment.where(patient_id: patient_ids).order(:patient_id)
  end
  # rubocop:enable Lint/UnusedMethodArgument
end

# Exception used for reporting validation errors
class InvalidQueryError < StandardError
  def initialize(field, value)
    super("Invalid Query (#{field}): #{value}")
  end
end
