# frozen_string_literal: true

require 'digest'

# Jurisdiction: jurisdiction model
class Jurisdiction < ApplicationRecord
  has_ancestry

  # Immediate patients are those just in this jurisdiction
  has_many :immediate_patients, class_name: 'Patient'

  has_many :threshold_conditions, class_name: 'ThresholdCondition'

  has_many :analytics, class_name: 'Analytic'

  scope :leaf_nodes, lambda {
    Jurisdiction.all.select{ |jur| jur.has_children? == false }
  }

  scope :non_leaf_nodes, lambda {
    Jurisdiction.all.select{ |jur| jur.has_children? == true }
  }

  # All patients are all those in this or descendent jurisdictions
  def all_patients
    Patient.where(jurisdiction_id: subtree_ids)
  end

  # Join this and parent jurisdictions names as a string
  def jurisdiction_path_string
    path&.map(&:name)&.join(', ')
  end

  # All patients that were in the jurisdiction before (but were transferred)
  def transferred_patients
    Patient.where(id: Transfer.where(from_jurisdiction_id: subtree_ids).pluck(:patient_id)).where.not(jurisdiction_id: id)
  end

  # The threadhold_hash is a way for an assessment to reference the set of symptoms and expected values that
  # are associated with the assessment
  def jurisdiction_path_threshold_hash
    theshold_conditions_edit_count = 0
    path&.map(&:threshold_conditions)&.each { |x| theshold_conditions_edit_count += x.count }
    jurisdiction_threshold_unique_string = jurisdiction_path_string + theshold_conditions_edit_count.to_s
    Digest::SHA256.hexdigest(jurisdiction_threshold_unique_string)
  end

  # This creates NEW condition that represents a join of all of the symptoms in your jurisdiciton hierarchy
  # Contains the values for the symptoms that will be what are considered as symptomatic
  def hierarchical_symptomatic_condition
    master_symptoms_list = []
    # Get array of arrays of symptoms, sorted top-down ie: usa set of symptoms first, state next etc...
    all_condition_symptoms = path&.map { |symp_defs| symp_defs.threshold_conditions.last&.symptoms }
    all_condition_symptoms&.each do |symptoms_list|
      symptoms_list&.each do |symptom|
        master_symptoms_list.push(symptom.dup) unless master_symptoms_list.include?(symptom.name)
      end
    end

    symptoms_list_hash = jurisdiction_path_threshold_hash
    if ThresholdCondition.where(threshold_condition_hash: symptoms_list_hash).count.zero?
      ThresholdCondition.create(symptoms: master_symptoms_list, threshold_condition_hash: symptoms_list_hash)
    end
    ThresholdCondition.where(threshold_condition_hash: symptoms_list_hash).first
  end

  def hierarchical_condition_unpopulated_symptoms
    threshold_condition = hierarchical_symptomatic_condition
    new_cond = ReportedCondition.new(threshold_condition_hash: threshold_condition.threshold_condition_hash)
    master_symptoms_list = []
    # Get array of arrays of symptoms, sorted top-down ie: usa set of symptoms first, state next etc...
    all_condition_symptoms = path&.map { |symp_defs| symp_defs.threshold_conditions.last&.symptoms }
    all_condition_symptoms&.each do |symptoms_list|
      symptoms_list&.each do |symptom|
        unless master_symptoms_list.include?(symptom.name)
          new_symptom = symptom.dup
          # Should put clear function in the symptom class(es)
          new_symptom.int_value = nil
          new_symptom.float_value = nil
          new_symptom.bool_value = nil
          master_symptoms_list.push(symptom.name)
          new_cond.symptoms.push(new_symptom)
        end
      end
    end
    new_cond
  end
end
