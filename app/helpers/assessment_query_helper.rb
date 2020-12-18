# frozen_string_literal: true

# Helper methods for filtering through assessments
module AssessmentQueryHelper
  def assessments_by_patient_ids(patient_ids)
    Assessment.where(patient_id: patient_ids).order(:patient_id)
  end

  def search(assessments, search)
    return assessments if search.blank?

    assessments.where('id like ?', "#{search&.downcase}%").or(
      assessments.where('who_reported like ?', "#{search&.downcase}%")
    )
  end

  def sort(assessments, order, direction)
    # Order by created_at date by default
    return assessments.order(created_at: 'desc') if order.blank? || direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = direction == 'asc' ? 'asc' : 'desc'

    # TODO: order assessments by their value for each symptom
    case order
    when 'id'
      assessments = assessments.order(id: dir)
    when 'symptomatic'
      assessments = assessments.order(symptomatic: dir)
    when 'who_reported'
      assessments = assessments.order(who_reported: dir)
    when 'created_at'
      assessments = assessments.order(created_at: dir)
    end
    assessments
  end

  def paginate(assessments, entries, page)
    return assessments if entries.blank? || entries <= 0 || page.blank? || page.negative?

    assessments.paginate(per_page: entries, page: page + 1)
  end

  def format(assessments)
    table_data = []
    columns = Assessment.get_symptom_names_for_assessments(assessments.pluck(:id))
    assessments.each do |assessment|
      reported_condition = assessment.reported_condition
      details = {
        id: assessment[:id],
        symptomatic: assessment.symptomatic ? 'Yes' : 'No',
        who_reported: assessment.who_reported,
        created_at: assessment.created_at,
        threshold_condition_hash: reported_condition&.threshold_condition&.threshold_condition_hash,
        symptoms: reported_condition&.symptoms
      }

      passes_threshold_data = {}
      columns.each do |symptom_name|
        reported_condition = assessment.get_reported_symptom_by_name(symptom_name)
        value = reported_condition&.value
        value = value == true ? 'Yes' : 'No' if reported_condition&.type == 'BoolSymptom'
        details[symptom_name] = value.blank? ? '' : value
        passes_threshold_data[symptom_name] = assessment.symptom_passes_threshold(symptom_name)
      end
      details[:passes_threshold_data] = passes_threshold_data
      table_data << details
    end
    { table_data: table_data, total: assessments.total_entries }
  end
end
