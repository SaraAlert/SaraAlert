# frozen_string_literal: true

# Assessment: assessment model
class Assessment < ApplicationRecord
  extend OrderAsSpecified
  include PatientHelper
  include ExcelSanitizer
  include FhirHelper

  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end
  has_one :reported_condition, class_name: 'ReportedCondition'
  belongs_to :patient, touch: true

  after_create { update_patient_linelist_fields(:created) }
  after_update { update_patient_linelist_fields(:updated) }
  after_destroy { update_patient_linelist_fields(:removed) }

  # Assessments created in the last hour that are symptomatic
  scope :symptomatic_last_hour, lambda {
    where('created_at >= ?', 60.minutes.ago)
      .where(symptomatic: true)
  }

  # Assessments created since the given time
  scope :created_since, lambda { |since|
    where('created_at >= ?', since)
  }

  # Assessments created by monitorees since the given time
  scope :monitoree_created_since, lambda { |since|
    where('created_at >= ?', since)
      .where(who_reported: %w[Monitoree Proxy])
  }

  # Assessments created by monitorees
  scope :created_by_monitoree, lambda {
    where(who_reported: %w[Monitoree Proxy])
  }

  # Assessments created by users
  scope :created_by_user, lambda {
    where.not(who_reported: %w[Monitoree Proxy])
  }

  def symptomatic?
    symptom_groups = []
    threshold_symptoms = reported_condition&.threshold_condition&.symptoms&.map { |threshold_symptom| [threshold_symptom[:name], threshold_symptom] }&.to_h
    reported_condition.symptoms.each do |reported_symptom|
      threshold_symptom = threshold_symptoms[reported_symptom.name] unless threshold_symptoms.nil?
      # Group represents how many have to be true in that group to be considered as symptomatic
      symptom_group_index = threshold_symptom&.group || 1
      # -1 to convert to 0-based ie: index 0 requires at least 1 true, index 1 requires at least 2 true...
      symptom_group_index -= 1
      symptom_passes = symptom_passes_threshold(reported_symptom, threshold_symptom)
      symptom_groups[symptom_group_index] = 0 if symptom_groups[symptom_group_index].nil?
      symptom_groups[symptom_group_index] += 1 if symptom_passes
    end
    symptomatic = false
    symptom_groups.each_with_index { |count, index| symptomatic ||= (count >= index + 1) unless count.nil? }
    symptomatic
  end

  # symptom_passes_threshold will return true if the REQUIRED symptom with the given name in the reported condition
  # meets the definition of symptomatic as defined in the assocated ThresholdCondition
  def symptom_passes_threshold(reported_symptom, threshold_symptom = nil)
    # This will be the case if a symptom is no longer being tracked and the assessments table is looking for its value
    return nil if reported_symptom.nil? || reported_symptom.value.nil?

    threshold_symptom = get_threshold_symptom(reported_symptom.name) if threshold_symptom.nil?
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
    reported_condition&.threshold_condition&.symptoms&.find_by(name: symptom_name)
  end

  def get_reported_symptom_value(symptom_name)
    reported_symptom = reported_condition&.symptoms&.find_by(name: symptom_name)

    # This will be the case if a symptom is no longer being tracked and the assessments table is looking for its value
    return nil if reported_symptom.nil?

    reported_symptom.value
  end

  def all_symptom_names
    reported_condition&.threshold_condition&.symptoms&.pluck(:name)
  end

  def get_reported_symptom_by_name(symptom_name)
    reported_condition&.symptoms&.find_by(name: symptom_name)
  end

  def translations
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    {
      eng: I18n.backend.send(:translations)[:eng][:assessments],
      spa: I18n.backend.send(:translations)[:spa][:assessments],
      'spa-pr': I18n.backend.send(:translations)[:'spa-pr'][:assessments],
      som: I18n.backend.send(:translations)[:som][:assessments],
      fra: I18n.backend.send(:translations)[:fra][:assessments]
    }
  end

  # Returns a representative FHIR::QuestionnaireResponse for an instance of a Sara Alert Assessment.
  # https://www.hl7.org/fhir/observation.html
  def as_fhir
    assessment_as_fhir(self)
  end

  private

  def update_patient_linelist_fields(action)
    latest_assessment = patient.assessments.order(:created_at).last
    updates = { latest_assessment_at: latest_assessment&.created_at, latest_assessment_symptomatic: latest_assessment&.symptomatic }

    # latest fever or fever reducer at only needs to be updated upon deletion as it is updated in the symptom model upon symptom creation
    if action == :removed
      updates[:latest_fever_or_fever_reducer_at] = patient.assessments.where_assoc_exists(:reported_condition, &:fever_or_fever_reducer).maximum(:created_at)
    end

    # wrap patient and history updates in transaction for consistency
    ActiveRecord::Base.transaction do
      # only update symptom onset if it's system defined or nil
      if !patient.user_defined_symptom_onset || patient.symptom_onset.nil?
        new_symptom_onset = calculated_symptom_onset(patient)
        updates[:symptom_onset] = new_symptom_onset
        History.calculated_symptom_onset(patient: patient, new_symptom_onset: new_symptom_onset, action: action)
      end

      patient.update(updates)
    end
  end
end
