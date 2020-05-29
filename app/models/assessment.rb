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

  scope :twenty_four_hours_fever, lambda {
    where('created_at >= ?', 24.hours.ago).where_assoc_exists(:reported_condition, &:fever)
  }

  scope :twenty_four_hours_fever_medication, lambda {
    where('created_at >= ?', 24.hours.ago).where_assoc_exists(:reported_condition, &:fever_medication)
  }

  scope :seventy_two_hours_fever, lambda {
    where('created_at >= ?', 72.hours.ago).where_assoc_exists(:reported_condition, &:fever)
  }

  scope :seventy_two_hours_fever_medication, lambda {
    where('created_at >= ?', 72.hours.ago).where_assoc_exists(:reported_condition, &:fever_medication)
  }

  scope :ten_days_symptomatic, lambda {
    where('created_at >= ?', 10.days.ago).where(symptomatic: true)
  }

  scope :created_last_seventy_two_hours, lambda {
    where('created_at >= ?', 72.hours.ago)
  }

  def symptomatic?
    symptom_groups = []
    reported_condition.symptoms.each do |reported_symptom|
      threshold_symptom = get_threshold_symptom(reported_symptom.name)
      # Group represents how many have to be true in that group to be considered as symptomatic
      symptom_group_index = threshold_symptom&.group || 1
      # -1 to convert to 0-based ie: index 0 requires atleast 1 true, index 1 requires atleast 2 true...
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

    if reported_symptom.type == 'FloatSymptom' || reported_symptom.type == 'IntegerSymptom'
      return true if threshold_operator == 'less than' && reported_symptom.value < threshold_symptom.value
      return true if threshold_operator == 'less than or equal' && reported_symptom.value <= threshold_symptom.value
      return true if threshold_operator == 'greater than' && reported_symptom.value > threshold_symptom.value
      return true if threshold_operator == 'greater than or equal' && reported_symptom.value >= threshold_symptom.value
      return true if threshold_operator == 'equal' && reported_symptom.value == threshold_symptom.value
      return true if threshold_operator == 'not equal' && reported_symptom.value != threshold_symptom.value
    elsif reported_symptom.type == 'BoolSymptom'
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
end
