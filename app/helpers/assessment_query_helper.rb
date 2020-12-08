# frozen_string_literal: true

# Helper methods for filtering through assessments
module AssessmentQueryHelper
  def assessments_by_query(patients_identifiers)
    Assessment.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end

  def extract_assessments_details(patients_identifiers, assessments, fields)
    if fields.include?(:symptoms)
      conditions = ReportedCondition.where(assessment_id: assessments.pluck(:id))
      symptoms = Symptom.where(condition_id: conditions.pluck(:id))

      conditions_hash = Hash[conditions.pluck(:id, :assessment_id).map { |id, assessment_id| [id, assessment_id] }]
                        .transform_values { |assessment_id| { assessment_id: assessment_id, symptoms: {} } }
      symptoms.each do |symptom|
        conditions_hash[symptom[:condition_id]][:symptoms][symptom[:name]] = symptom.value
      end
      assessments_hash = Hash[conditions_hash.map { |_, condition| [condition[:assessment_id], condition[:symptoms]] }]
    end

    symptom_names = symptoms&.distinct&.pluck(:name)

    assessments_details = []
    assessments.each do |assessment|
      assessment_details = {}
      assessment_details[:patient_id] = assessment[:patient_id] || '' if fields.include?(:patient_id)
      %i[user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss].each do |identifier|
        assessment_details[identifier] = patients_identifiers[assessment[:patient_id]][identifier] || '' if fields.include?(identifier)
      end
      assessment_details[:id] = assessment[:id] || '' if fields.include?(:id)
      assessment_details[:symptomatic] = assessment[:symptomatic] || false if fields.include?(:symptomatic)
      assessment_details[:who_reported] = assessment[:who_reported] || '' if fields.include?(:who_reported)
      assessment_details[:created_at] = assessment[:created_at]&.strftime('%F') || '' if fields.include?(:created_at)
      assessment_details[:updated_at] = assessment[:updated_at]&.strftime('%F') || '' if fields.include?(:updated_at)
      if fields.include?(:symptoms)
        symptom_names.each do |symptom_name|
          assessment_details[symptom_name.to_sym] = assessments_hash[assessment[:id]][symptom_name]
        end
      end
      assessments_details << assessment_details
    end
    [assessments_details, symptom_names]
  end
end
