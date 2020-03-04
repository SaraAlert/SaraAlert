# frozen_string_literal: true

# Assessment: assessment model
class Assessment < ApplicationRecord
  # TODO: There's currently a hard coded symptom list, but those should be configurable
  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end
  has_one :reported_condition, :class_name => 'ReportedCondition'
  belongs_to :patient

  def is_symptomatic
    symptomatic = false
    reported_condition.symptoms.each{ |reported_symptom|
      symptomatic = symptomatic || symptom_passes_threshold(reported_symptom.name)
    }
    return symptomatic
  end

  # symptom_passes_threshold will return true if the symptom with the given name in the reported condition
  # meets the definition of symptomatic as defined in the assocated ThresholdCondition
  def symptom_passes_threshold(symptom_name)
    reported_symptom = reported_condition.symptoms.select{|symp| symp.name == symptom_name}[0]
    # This will be the case if a symptom is no longer being tracked and the assessments table is looking for its value
    if reported_symptom == nil
      return nil
    end
    threshold_condition = reported_condition.get_threshold_condition
    threshold_symptom = threshold_condition.symptoms.select{|symp| symp.name == symptom_name}[0]
    if reported_symptom.type == "FloatSymptom"
      if reported_symptom.float_value >= threshold_symptom.float_value
        return true
      end
    elsif reported_symptom.type  == "BoolSymptom"
      if reported_symptom.bool_value === threshold_symptom.bool_value
        return true
      end
    elsif reported_symptom.type  == "IntegerSymptom"
      if reported_symptom.int_value >= threshold_symptom.int_value
        return true
      end
    end
    return false
  end

  def get_reported_symptom_value(symptom_name)
    reported_symptom = reported_condition.symptoms.select{|symp| symp.name == symptom_name}[0]
    # This will be the case if a symptom is no longer being tracked and the assessments table is looking for its value
    if reported_symptom == nil
      return nil
    end
    if reported_symptom.type == "FloatSymptom"
      return reported_symptom.float_value
    elsif reported_symptom.type  == "BoolSymptom"
      return reported_symptom.bool_value
    elsif reported_symptom.type  == "IntegerSymptom"
      return reported_symptom.int_value
    end
  end

  def get_all_symptom_names
    return reported_condition.symptoms.collect{|x| x.name}
  end

  def get_reported_symptom_by_name(symptom_name)
     return reported_condition.symptoms.select{|symp| symp.name == symptom_name}[0]
  end

end
