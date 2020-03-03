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
  has_one :symptomatic_condition, :class_name => 'ThresholdCondition'
  belongs_to :patient

  def is_symptomatic
    reported_condition.symptoms.each{ |reported_symptom|
      threshold_symptom = symptomatic_condition.symptoms.select{|symp| symp.name == reported_symptom.name}[0]
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
    }
    return false;
  end
end
