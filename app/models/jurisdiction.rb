# frozen_string_literal: true

require 'digest'

# Jurisdiction: jurisdiction model
class Jurisdiction < ApplicationRecord
  has_ancestry

  # Immediate patients are those just in this jurisdiction
  has_many :immediate_patients, class_name: 'Patient'

  has_many :threshold_conditions, class_name: 'ThresholdCondition'

  has_many :analytics, class_name: 'Analytic'

  has_many :stats, class_name: 'Stat'

  # Find the USA Jurisdiction
  def self.root
    Jurisdiction.find_by(name: 'USA')
  end

  # All patients are all those in this or descendent jurisdictions (including purged)
  def all_patients_including_purged
    Patient.where(jurisdiction_id: subtree_ids)
  end

  # All patients are all those in this or descendent jurisdictions (excluding purged)
  def all_patients_excluding_purged
    all_patients_including_purged.where(purged: false)
  end

  # All users that are in this or descendent jurisdictions
  def all_users
    User.where(jurisdiction_id: subtree_ids)
  end

  def assigned_users
    immediate_patients.where.not(assigned_user: nil).distinct.pluck(:assigned_user).sort
  end

  # All patients that were in the jurisdiction before (but were transferred), and are not currently in the subtree
  def transferred_out_patients
    Patient.where(purged: false, id: Transfer.where(from_jurisdiction_id: subtree_ids).pluck(:patient_id)).where.not(jurisdiction_id: subtree_ids + [id])
  end

  # All patients that were transferred into the jurisdiction in the last 24 hours
  def transferred_in_patients
    Patient.where(purged: false, id: Transfer.where(to_jurisdiction_id: subtree_ids + [id])
                              .where.not(from_jurisdiction_id: subtree_ids + [id])
                              .where('created_at > ?', 24.hours.ago).pluck(:patient_id))
           .where(jurisdiction_id: subtree_ids + [id])
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

  # This calculates the current threshold condition hash which is usually only meant to be called after updating threshold conditions
  # Otherwise, simply reference the :current_threshold_condition_hash field to avoid extra computation and queries
  def calculate_current_threshold_condition_hash
    Digest::SHA256.hexdigest(self[:path] + ThresholdCondition.where(jurisdiction_id: path_ids).size.to_s)
  end

  # This creates NEW condition that represents a join of all of the symptoms in your jurisdiciton hierarchy
  # Contains the values for the symptoms that will be what are considered as symptomatic
  def hierarchical_symptomatic_condition
    threshold_condition = ThresholdCondition.where(threshold_condition_hash: current_threshold_condition_hash).first

    # This condition _should_ only be true when the jurisdiction add/update task is run
    return threshold_condition unless threshold_condition.nil?

    master_symptoms_list = []
    # Get array of arrays of symptoms, sorted top-down ie: usa set of symptoms first, state next etc...
    all_condition_symptoms = path&.map { |symp_defs| symp_defs.threshold_conditions.last&.symptoms }
    all_condition_symptoms&.each do |symptoms_list|
      symptoms_list&.each do |symptom|
        master_symptoms_list.push(symptom.dup) unless master_symptoms_list.include?(symptom.name)
      end
    end
    ThresholdCondition.create(symptoms: master_symptoms_list, threshold_condition_hash: current_threshold_condition_hash)
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

  def hierarchical_condition_bool_symptoms_string(lang = :eng)
    hierarchical_condition = hierarchical_symptomatic_condition
    bool_symptom_labels = hierarchical_condition.symptoms.where(required: true).collect do |symptom|
      symptom.bool_based_prompt(lang)
    end
    bool_symptom_labels.join(', ')
  end
end
