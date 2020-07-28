# frozen_string_literal: true

require 'digest'

# Jurisdiction: jurisdiction model
class Jurisdiction < ApplicationRecord
  has_ancestry

  # Immediate patients are those just in this jurisdiction
  has_many :immediate_patients, class_name: 'Patient'

  has_many :threshold_conditions, class_name: 'ThresholdCondition'

  has_many :analytics, class_name: 'Analytic'

  # All patients are all those in this or descendent jurisdictions
  def all_patients
    Patient.includes([:jurisdiction]).where(jurisdiction_id: subtree_ids)
  end

  # Join this and parent jurisdictions names as a string
  def jurisdiction_path_string
    path&.map(&:name)&.join(', ')
  end

  def assigned_users
    immediate_patients.where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort
  end

  def all_assigned_users
    all_patients.where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort
  end

  # All patients that were in the jurisdiction before (but were transferred), and are not currently in the subtree
  def transferred_out_patients
    Patient.where(id: Transfer.where(from_jurisdiction_id: subtree_ids).pluck(:patient_id)).where.not(jurisdiction_id: subtree_ids + [id])
  end

  # All patients that were transferred into the jurisdiction in the last 24 hours
  def transferred_in_patients
    Patient.where(id: Transfer.where(to_jurisdiction_id: subtree_ids + [id])
                              .where.not(from_jurisdiction_id: subtree_ids + [id])
                              .where('created_at > ?', 24.hours.ago).pluck(:patient_id))
           .where(jurisdiction_id: subtree_ids + [id])
  end

  # The threshold_hash is a way for an assessment to reference the set of symptoms and expected values that
  # are associated with the assessment
  # It is better to call hierarchical_symptomatic_condition.threshold_condition_hash because it guarentees that
  # the threshold condtition that this hash references _actually_ exists
  def jurisdiction_path_threshold_hash
    theshold_conditions_edit_count = 0
    path&.map(&:threshold_conditions)&.each { |x| theshold_conditions_edit_count += x.count }
    jurisdiction_threshold_unique_string = jurisdiction_path_string + theshold_conditions_edit_count.to_s
    Digest::SHA256.hexdigest(jurisdiction_threshold_unique_string)
  end

  # This will return the first available contact info (email, phone, and/or webpage)
  # discovered along this jurisdiction's path
  def contact_info
    contact_info = { email: '', phone: '', webpage: '' }
    # Iterate over path in reverse so that we will be starting _at_ the current jurisdiction
    path&.reverse&.each do |jur|
      unless jur.phone.blank? && jur.email.blank? && jur.webpage.blank?
        contact_info[:email] = jur.email || ''
        contact_info[:phone] = jur.phone || ''
        contact_info[:webpage] = jur.webpage || ''
        break
      end
    end
    contact_info
  end

  # This creates NEW condition that represents a join of all of the symptoms in your jurisdiciton hierarchy
  # Contains the values for the symptoms that will be what are considered as symptomatic
  def hierarchical_symptomatic_condition
    symptoms_list_hash = jurisdiction_path_threshold_hash
    # This condition _should_ only be true when the jurisdiction add/update task is run
    if ThresholdCondition.where(threshold_condition_hash: symptoms_list_hash).count.zero?
      master_symptoms_list = []
      # Get array of arrays of symptoms, sorted top-down ie: usa set of symptoms first, state next etc...
      all_condition_symptoms = path&.map { |symp_defs| symp_defs.threshold_conditions.last&.symptoms }
      all_condition_symptoms&.each do |symptoms_list|
        symptoms_list&.each do |symptom|
          master_symptoms_list.push(symptom.dup) unless master_symptoms_list.include?(symptom.name)
        end
      end
      ThresholdCondition.create(symptoms: master_symptoms_list, threshold_condition_hash: symptoms_list_hash)
    end
    ThresholdCondition.where(threshold_condition_hash: symptoms_list_hash).first
  end

  def hierarchical_condition_unpopulated_symptoms
    threshold_condition = hierarchical_symptomatic_condition
    new_cond = ReportedCondition.new(threshold_condition_hash: threshold_condition.threshold_condition_hash)
    # Get array of arrays of symptoms, sorted top-down ie: usa set of symptoms first, state next etc...
    threshold_condition.symptoms&.each do |symptom|
      new_symptom = symptom.dup
      # Should put clear function in the symptom class(es)
      new_symptom.value = nil
      new_cond.symptoms.push(new_symptom)
    end
    new_cond
  end

  def hierarchical_condition_bool_symptoms_string(lang = :en)
    hierarchical_condition = hierarchical_symptomatic_condition
    bool_symptom_labels = hierarchical_condition.symptoms.where(required: true).collect do |symptom|
      symptom.bool_based_prompt(lang)
    end
    bool_symptom_labels.join(', ')
  end
end
