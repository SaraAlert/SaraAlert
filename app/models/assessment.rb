# frozen_string_literal: true

# Assessment: assessment model
class Assessment < ApplicationRecord
  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end
  has_one :reported_condition, class_name: 'ReportedCondition'
  belongs_to :patient

  after_save :update_patient_linelist_after_save
  before_destroy :update_patient_linelist_before_destroy

  def symptomatic?
    symptom_groups = []
    reported_condition.symptoms.each do |reported_symptom|
      threshold_symptom = get_threshold_symptom(reported_symptom.name)
      # Group represents how many have to be true in that group to be considered as symptomatic
      symptom_group_index = threshold_symptom&.group || 1
      # -1 to convert to 0-based ie: index 0 requires at least 1 true, index 1 requires at least 2 true...
      symptom_group_index -= 1
      symptom_passes = symptom_passes_threshold(reported_symptom.name, threshold_symptom)
      symptom_groups[symptom_group_index] = 0 if symptom_groups[symptom_group_index].nil?
      symptom_groups[symptom_group_index] += 1 if symptom_passes
    end
    symptomatic = false
    symptom_groups.each_with_index { |count, index| symptomatic ||= (count >= index + 1) unless count.nil? }
    symptomatic
  end

  # symptom_passes_threshold will return true if the REQUIRED symptom with the given name in the reported condition
  # meets the definition of symptomatic as defined in the assocated ThresholdCondition
  def symptom_passes_threshold(symptom_name, threshold_symptom = nil)
    reported_symptom = reported_condition&.symptoms&.select { |symp| symp.name == symptom_name }&.first
    # This will be the case if a symptom is no longer being tracked and the assessments table is looking for its value
    return nil if reported_symptom.nil? || reported_symptom.value.nil?

    threshold_symptom = get_threshold_symptom(symptom_name) if threshold_symptom.nil?
    return false unless threshold_symptom&.required?

    return nil if threshold_symptom.nil? || threshold_symptom.value.nil?

    threshold_operator = threshold_symptom&.threshold_operator&.downcase
    threshold_operator ||= 'less than'

    case reported_symptom.type
    when 'FloatSymptom', 'IntegerSymptom'
      return true if threshold_operator == 'less than' && reported_symptom.value < threshold_symptom.value
      return true if threshold_operator == 'less than or equal' && reported_symptom.value <= threshold_symptom.value
      return true if threshold_operator == 'greater than' && reported_symptom.value > threshold_symptom.value
      return true if threshold_operator == 'greater than or equal' && reported_symptom.value >= threshold_symptom.value
      return true if threshold_operator == 'equal' && reported_symptom.value == threshold_symptom.value
      return true if threshold_operator == 'not equal' && reported_symptom.value != threshold_symptom.value
    when 'BoolSymptom'
      return reported_symptom.value != threshold_symptom.value if threshold_operator == 'not equal'
      # Bool symptom threshold_operator will fall back to equal
      return true if reported_symptom.value == threshold_symptom.value
    end
    false
  end

  def get_threshold_symptom(symptom_name)
    threshold_condition = reported_condition&.threshold_condition
    threshold_condition&.symptoms&.select { |symp| symp.name == symptom_name }&.first
  end

  def get_reported_symptom_value(symptom_name)
    reported_symptom = reported_condition.symptoms.select { |symp| symp.name == symptom_name }[0]
    # This will be the case if a symptom is no longer being tracked and the assessments table is looking for its value
    return nil if reported_symptom.nil?

    reported_symptom.value
  end

  def all_symptom_names
    reported_condition&.threshold_condition&.symptoms&.collect { |x| x.name } || []
  end

  def get_reported_symptom_by_name(symptom_name)
    reported_condition&.symptoms&.select { |symp| symp.name == symptom_name }&.first || nil
  end

  def translations
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    {
      en: I18n.backend.send(:translations)[:en][:assessments],
      es: I18n.backend.send(:translations)[:es][:assessments],
      'es-PR': I18n.backend.send(:translations)[:'es-PR'][:assessments],
      so: I18n.backend.send(:translations)[:so][:assessments],
      fr: I18n.backend.send(:translations)[:fr][:assessments]
    }
  end

  # Returns a representative FHIR::QuestionnaireResponse for an instance of a Sara Alert Assessment.
  # https://www.hl7.org/fhir/observation.html
  def as_fhir
    FHIR::QuestionnaireResponse.new(
      meta: FHIR::Meta.new(lastUpdated: updated_at.strftime('%FT%T%:z')),
      id: id,
      subject: FHIR::Reference.new(reference: "Patient/#{patient_id}"),
      status: 'completed',
      item: reported_condition.symptoms.enum_for(:each_with_index).collect do |s, index|
        case s.type
        when 'IntegerSymptom'
          FHIR::QuestionnaireResponse::Item.new(text: s.name,
                                                answer: FHIR::QuestionnaireResponse::Item::Answer.new(valueInteger: s.int_value),
                                                linkId: index.to_s)
        when 'FloatSymptom'
          FHIR::QuestionnaireResponse::Item.new(text: s.name,
                                                answer: FHIR::QuestionnaireResponse::Item::Answer.new(valueDecimal: s.float_value),
                                                linkId: index.to_s)
        when 'BoolSymptom'
          FHIR::QuestionnaireResponse::Item.new(text: s.name,
                                                answer: FHIR::QuestionnaireResponse::Item::Answer.new(valueBoolean: s.bool_value),
                                                linkId: index.to_s)
        end
      end
    )
  end

  private

  def update_patient_linelist_after_save
    if patient.user_defined_symptom_onset.present? && !patient.symptom_onset.nil?
      patient.update(
        latest_assessment_at: patient.assessments.maximum(:created_at)
      )
    else
      patient.update(
        latest_assessment_at: patient.assessments.maximum(:created_at),
        symptom_onset: patient.assessments.where(symptomatic: true).minimum(:created_at)
      )
    end
  end

  def update_patient_linelist_before_destroy
    # latest fever or fever reducer at only needs to be updated upon deletion as it is updated in the symptom model upon symptom creation
    if patient.user_defined_symptom_onset.present? && !patient.symptom_onset.nil?
      patient.update(
        latest_assessment_at: patient.assessments.where.not(id: id).maximum(:created_at),
        latest_fever_or_fever_reducer_at: patient.assessments
                                                 .where.not(id: id)
                                                 .where_assoc_exists(:reported_condition, &:fever_or_fever_reducer)
                                                 .maximum(:created_at)
      )
    else
      patient.update(
        symptom_onset: patient.assessments.where.not(id: id).where(symptomatic: true).minimum(:created_at),
        latest_assessment_at: patient.assessments.where.not(id: id).maximum(:created_at),
        latest_fever_or_fever_reducer_at: patient.assessments
                                                 .where.not(id: id)
                                                 .where_assoc_exists(:reported_condition, &:fever_or_fever_reducer)
                                                 .maximum(:created_at)
      )
    end
  end
end
