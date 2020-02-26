# frozen_string_literal: true

# Jurisdiction: jurisdiction model
class Jurisdiction < ApplicationRecord
  has_ancestry

  # Immediate patients are those just in this jurisdiction
  has_many :immediate_patients, class_name: 'Patient'
 
  has_many :symptomatic_definitions, class_name: 'Condition'

  # All patients are all those in this or descendent jurisdictions
  def all_patients
    Patient.where(jurisdiction_id: subtree_ids)
  end

  def jurisdiction_path_string
    path&.map(&:name)&.join(', ')
  end

  # This creates NEW condition that represents a join of all of the symptoms in your jurisdiciton hierarchy
  def full_symptomatic_condition
    master_symptoms_list = []
    # Get array of arrays of symptoms, sorted top-down ie: usa set of symptoms first, state next etc...
    all_condition_symptoms = path&.map{|symp_defs| symp_defs.symptomatic_definitions.last&.symptoms}
    all_condition_symptoms&.each{|symptoms_list| 
      symptoms_list&.each{ |symptom| 
        if !(master_symptoms_list.include?(symptom.name))
          master_symptoms_list.push(symptom.clone())
        end
      }
    }

    return Condition.create(symptoms: master_symptoms_list)
  end

end
