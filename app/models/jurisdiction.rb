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
  # Contains the values for the symptoms that will be what are considered as symptomatic
  def hierarchical_symptomatic_condition
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

    return Condition.new(symptoms: master_symptoms_list)
  end


  def hierarchical_condition_unpopulated_symptoms
    new_cond = Condition.new()
    master_symptoms_list = []
    # Get array of arrays of symptoms, sorted top-down ie: usa set of symptoms first, state next etc...
    all_condition_symptoms = path&.map{|symp_defs| symp_defs.symptomatic_definitions.last&.symptoms}
    all_condition_symptoms&.each{|symptoms_list| 
      symptoms_list&.each{ |symptom| 
        if !(master_symptoms_list.include?(symptom.name))
          new_symptom = symptom.dup()
          # Should put clear function in the symptom class(es)
          new_symptom.int_value = nil
          new_symptom.float_value = nil
          new_symptom.bool_value = nil
          master_symptoms_list.push(symptom.name)
          new_cond.symptoms.push(new_symptom)
        end
      }
    }
    return new_cond
  end

end
