# frozen_string_literal: true

# Assessment: assessment model
class Assessment < ApplicationRecord
  extend OrderAsSpecified
  include PatientHelper
  include ExcelSanitizer

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

  after_save :update_patient_linelist_after_save
  after_destroy :update_patient_linelist_after_destroy

  # Assessments created in the last hour that are symptomatic
  scope :symptomatic_last_hour, lambda {
    where('created_at >= ?', 60.minutes.ago)
      .where(symptomatic: true)
  }

  # Assessments created since the given time
  scope :created_since, lambda { |since|
    where('created_at >= ?', since)
  }

  # Assessments created by monitorees
  scope :created_by_monitoree, lambda {
    where(who_reported: %w[Monitoree Proxy])
  }

  def symptomatic?
    symptom_groups = []
    reported_condition.symptoms.each do |reported_symptom|
      threshold_symptom = get_threshold_symptom(reported_symptom.name)
      # Group represents how many have to be true in that group to be considered as symptomatic
      symptom_group_index = threshold_symptom&.group || 1
      # -1 to convert to 0-based ie: index 0 requires at least 1 true, index 1 requires at least 2 true...
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
    reported_symptom = reported_condition&.symptoms&.find_by(name: symptom_name)
    # This will be the case if a symptom is no longer being tracked and the assessments table is looking for its value
    return nil if reported_symptom.nil? || reported_symptom.value.nil?

    threshold_symptom = get_threshold_symptom(symptom_name) if threshold_symptom.nil?
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

  # Gets all unique symptoms (based on name) for a given array of assessment IDs.
  def self.get_unique_symptoms_for_assessments(assessment_ids)
    threshold_cond_hashes = ReportedCondition.where(type: 'ReportedCondition', assessment_id: assessment_ids)&.pluck(:threshold_condition_hash)
    return if threshold_cond_hashes.nil?

    condition_ids = ThresholdCondition.where(type: 'ThresholdCondition', threshold_condition_hash: threshold_cond_hashes)
    Symptom.where(condition_id: condition_ids)&.uniq(&:name)
  end

  def translations
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    {
      en: I18n.backend.send(:translations)[:en][:assessments],
      es: I18n.backend.send(:translations)[:es][:assessments],
      'es-PR': I18n.backend.send(:translations)[:'es-PR'][:assessments],
      so: I18n.backend.send(:translations)[:so][:assessments],
      fr: I18n.backend.send(:translations)[:fr][:assessments]
    }
  end

  # Returns a representative FHIR::QuestionnaireResponse for an instance of a Sara Alert Assessment.
  # https://www.hl7.org/fhir/observation.html
  def as_fhir
    FHIR::QuestionnaireResponse.new(
      meta: FHIR::Meta.new(lastUpdated: updated_at.strftime('%FT%T%:z')),
      id: id,
      subject: FHIR::Reference.new(reference: "Patient/#{patient_id}"),
      status: 'completed',
      item: reported_condition.symptoms.enum_for(:each_with_index).collect do |s, index|
        case s.type
        when 'IntegerSymptom'
          FHIR::QuestionnaireResponse::Item.new(text: s.name,
                                                answer: FHIR::QuestionnaireResponse::Item::Answer.new(valueInteger: s.int_value),
                                                linkId: index.to_s)
        when 'FloatSymptom'
          FHIR::QuestionnaireResponse::Item.new(text: s.name,
                                                answer: FHIR::QuestionnaireResponse::Item::Answer.new(valueDecimal: s.float_value),
                                                linkId: index.to_s)
        when 'BoolSymptom'
          FHIR::QuestionnaireResponse::Item.new(text: s.name,
                                                answer: FHIR::QuestionnaireResponse::Item::Answer.new(valueBoolean: s.bool_value),
                                                linkId: index.to_s)
        end
      end
    )
  end

  private

  def update_patient_linelist_after_save
    latest_assessment = patient.assessments.order(:created_at).last

    if patient.user_defined_symptom_onset.present? && !patient.symptom_onset.nil?
      patient.update(
        latest_assessment_at: latest_assessment&.created_at,
        latest_assessment_symptomatic: latest_assessment&.symptomatic
      )
    else
      new_symptom_onset = patient.assessments.where(symptomatic: true).minimum(:created_at)&.to_date
      unless new_symptom_onset == patient[:symptom_onset]
        comment = if !patient[:symptom_onset].nil? && !new_symptom_onset.nil?
                    "System changed symptom onset date from #{patient[:symptom_onset].strftime('%m/%d/%Y')} to #{new_symptom_onset.strftime('%m/%d/%Y')}
                     because a report meeting the symptomatic logic was created or updated."
                  elsif patient[:symptom_onset].nil? && !new_symptom_onset.nil?
                    "System changed symptom onset date from blank to #{new_symptom_onset.strftime('%m/%d/%Y')}
                     because a report meeting the symptomatic logic was created or updated."
                  elsif !patient[:symptom_onset].nil? && new_symptom_onset.nil?
                    "System cleared symptom onset date from #{patient[:symptom_onset].strftime('%m/%d/%Y')} to blank
                     because a report meeting the symptomatic logic was created or updated."
                  end
        History.monitoring_change(patient: patient, created_by: 'Sara Alert System', comment: comment)
      end
      patient.update(
        latest_assessment_at: latest_assessment&.created_at,
        latest_assessment_symptomatic: latest_assessment&.symptomatic,
        symptom_onset: new_symptom_onset
      )
    end
  end

  def update_patient_linelist_after_destroy
    latest_assessment = patient.assessments.where.not(id: id).order(:created_at).last

    # latest fever or fever reducer at only needs to be updated upon deletion as it is updated in the symptom model upon symptom creation
    if patient.user_defined_symptom_onset.present? && !patient.symptom_onset.nil?
      patient.update(
        latest_assessment_at: latest_assessment&.created_at,
        latest_assessment_symptomatic: latest_assessment&.symptomatic,
        latest_fever_or_fever_reducer_at: patient.assessments
                                                 .where.not(id: id)
                                                 .where_assoc_exists(:reported_condition, &:fever_or_fever_reducer)
                                                 .maximum(:created_at)
      )
    else
      new_symptom_onset = calculated_symptom_onset(patient)
      unless new_symptom_onset == patient[:symptom_onset] || !new_symptom_onset.nil?
        comment = "System cleared symptom onset date from #{patient[:symptom_onset].strftime('%m/%d/%Y')} to blank because a symptomatic report was removed."
        History.monitoring_change(patient: patient, created_by: 'Sara Alert System', comment: comment)
      end
      patient.update(
        symptom_onset: new_symptom_onset,
        latest_assessment_at: latest_assessment&.created_at,
        latest_assessment_symptomatic: latest_assessment&.symptomatic,
        latest_fever_or_fever_reducer_at: patient.assessments
                                                 .where.not(id: id)
                                                 .where_assoc_exists(:reported_condition, &:fever_or_fever_reducer)
                                                 .maximum(:created_at)
      )
    end
  end
end
