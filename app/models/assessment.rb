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

  def symptomatic?
    symptomatic = false
    reported_condition.symptoms.each do |reported_symptom|
      symptomatic ||= symptom_passes_threshold(reported_symptom.name)
    end
    symptomatic
  end

  # symptom_passes_threshold will return true if the symptom with the given name in the reported condition
  # meets the definition of symptomatic as defined in the assocated ThresholdCondition
  def symptom_passes_threshold(symptom_name)
    reported_symptom = reported_condition.symptoms.select { |symp| symp.name == symptom_name }[0]
    # This will be the case if a symptom is no longer being tracked and the assessments table is looking for its value
    return nil if reported_symptom.nil? || reported_symptom.value.nil?

    threshold_condition = reported_condition.threshold_condition
    threshold_symptom = threshold_condition.symptoms.select { |symp| symp.name == symptom_name }[0]
    if reported_symptom.type == 'FloatSymptom' || reported_symptom.type == 'IntegerSymptom'
      return true if reported_symptom.value >= threshold_symptom.value
    elsif reported_symptom.type == 'BoolSymptom'
      return true if reported_symptom.value == threshold_symptom.value
    end
    false
  end

  def get_reported_symptom_value(symptom_name)
    reported_symptom = reported_condition.symptoms.select { |symp| symp.name == symptom_name }[0]
    # This will be the case if a symptom is no longer being tracked and the assessments table is looking for its value
    return nil if reported_symptom.nil?

    reported_symptom.value
  end

  def all_symptom_names
    reported_condition&.symptoms&.collect { |x| x.name } || []
  end

  def get_reported_symptom_by_name(symptom_name)
    reported_condition&.symptoms&.select { |symp| symp.name == symptom_name }&.first || nil
  end
end
