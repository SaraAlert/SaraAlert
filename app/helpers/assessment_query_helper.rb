# frozen_string_literal: true

# Helper methods for filtering through assessments
module AssessmentQueryHelper
  def assessments_by_patient_ids(patient_ids)
    Assessment.where(patient_id: patient_ids).order(:patient_id)
  end

  # Queries assessments by ID or reporter based on search text.
  def search(assessments, search)
    return assessments if search.blank?

    assessments.where('id like ?', "#{search&.downcase}%").or(
      assessments.where('who_reported like ?', "#{search&.downcase}%")
    )
  end

  # Sorts assessments based on given column and direction.
  def sort(assessments, order, direction)
    # Order by created_at date by default
    return assessments.order(created_at: 'desc') if order.blank? || direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = direction == 'asc' ? 'asc' : 'desc'

    case order
    when 'id'
      assessments = assessments.order(id: dir)
    when 'symptomatic'
      assessments = assessments.order(symptomatic: dir)
    when 'who_reported'
      assessments = assessments.order(who_reported: dir)
    when 'created_at'
      assessments = assessments.order(created_at: dir)
    else
      # Verify this is a sort request for a symptom column.
      symptom_columns = Assessment.get_unique_symptoms_for_assessments(assessments.pluck(:id)).pluck(:name)
      return assessments unless symptom_columns&.include?(order)

      # Find assessment IDs based on the value of the symptom in the specified column
      ordered_values = assessments.map do |a|
        symptom = a.get_reported_symptom_by_name(order)
        # This check makes BoolSymptoms have a value of 1 or 0 rather than true/false so they can be compared
        value = symptom&.bool_value.nil? ? symptom&.value : (symptom&.value ? 1 : 0)
        { id: a.id, val: value }
      end

      # This sort makes it so nil values are considered the smallest (and always at the bottom in descending order)
      ordered_values = ordered_values.sort { |a, b| a[:val] && b[:val] ? a[:val] <=> b[:val] : a[:val] ? 1 : -1 }

      # Reverse if in descending order
      ordered_values = ordered_values.reverse if dir == 'desc'

      # Collect just the assessment IDs
      ordered_assessment_ids = ordered_values.collect { |res| res[:id] }

      # Find the assessment records based on the order of the IDs that were sorted above
      assessments = assessments.order_as_specified(id: ordered_assessment_ids)
    end
    assessments
  end

  # Paginates assessments data.
  def paginate(assessments, entries, page)
    return assessments if entries.blank? || entries <= 0 || page.blank? || page.negative?

    assessments.paginate(per_page: entries, page: page + 1)
  end

  # Formats assessments to be displayed on the frontend.
  def format(assessments)
    table_data = []
    symptoms = Assessment.get_unique_symptoms_for_assessments(assessments.pluck(:id))

    assessments.each do |assessment|
      reported_condition = assessment.reported_condition
      details = {
        id: assessment[:id],
        symptomatic: assessment.symptomatic ? 'Yes' : 'No',
        who_reported: assessment.who_reported,
        created_at: assessment.created_at,
        threshold_condition_hash: reported_condition&.threshold_condition&.threshold_condition_hash,
        symptoms: reported_condition&.symptoms&.uniq(&:name)
      }

      passes_threshold_data = {}
      symptoms&.pluck(:name)&.each do |symptom_name|
        symptom = assessment.get_reported_symptom_by_name(symptom_name)
        value = symptom&.value
        # NOTE: We must check if the value is nil here before making this change.
        # Otherwise, text responses of "Yes" will show "No" in each row because the value for each symptom is still empty, for example.
        if symptom&.type == 'BoolSymptom' && !value.nil?
          value = value == true ? 'Yes' : 'No'
        end
        details[symptom_name] = value.nil? ? '' : value
        passes_threshold_data[symptom_name] = assessment.symptom_passes_threshold(symptom_name)
      end
      details[:passes_threshold_data] = passes_threshold_data
      table_data << details
    end
    { table_data: table_data, symptoms: symptoms || [], total: assessments.total_entries }
  end
end
