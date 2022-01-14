# frozen_string_literal: true

# Symptom
class Symptom < ApplicationRecord
  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end

  def self.valid_types
    %w[FloatSymptom BoolSymptom IntegerSymptom]
  end

  validates :type, inclusion: valid_types, presence: true

  before_destroy :update_patient_linelist_before_destroy
  after_save :update_patient_linelist_after_save

  scope :fever_or_fever_reducer, lambda {
    where(['(name = ? OR name = ?) AND bool_value = ?', 'fever', 'used-a-fever-reducer', true])
  }

  def bool_based_prompt(lang = :eng, gsm_7: false)
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    symptom_name = if gsm_7
                     I18n.t("assessments.symptoms.#{name}.name-gsm-7", locale: lang, default: I18n.t("assessments.symptoms.#{name}.name", locale: lang))
                   else
                     I18n.t("assessments.symptoms.#{name}.name", locale: lang)
                   end
    case type
    when 'BoolSymptom'
      symptom_name
    when 'IntegerSymptom', 'FloatSymptom'
      [
        symptom_name,
        if gsm_7
          I18n.t(
            "assessments.threshold-op.#{threshold_operator.parameterize}-gsm-7",
            locale: lang,
            default: I18n.t("assessments.threshold-op.#{threshold_operator.parameterize}", locale: lang)
          )
        else
          I18n.t("assessments.threshold-op.#{threshold_operator.parameterize}", locale: lang)
        end,
        value
      ].to_sentence(words_connector: ' ', last_word_connector: ' ').humanize
    end
  end

  def as_json(options = {})
    super(options).merge({
                           type: type
                         })
  end

  def value
    case type
    when 'BoolSymptom'
      bool_value
    when 'IntegerSymptom'
      int_value
    when 'FloatSymptom'
      float_value
    end
  end

  def negate
    raise 'negation for this symptom type is not supported'
  end

  private

  def update_patient_linelist_after_save
    patient = Patient.joins(assessments: :reported_condition).where(conditions: { id: condition_id }).first
    return unless patient

    patient.update(
      latest_fever_or_fever_reducer_at: patient.assessments
                                              .where_assoc_exists(:reported_condition, &:fever_or_fever_reducer)
                                              .maximum(:created_at)
    )
  end

  def update_patient_linelist_before_destroy
    patient = Patient.joins(assessments: :reported_condition).where(conditions: { id: condition_id }).first
    return unless patient

    patient.update(
      latest_fever_or_fever_reducer_at: Assessment.joins(:reported_condition)
                                                  .where(id: patient.assessments)
                                                  .where.not('conditions.id = ?', condition_id)
                                                  .where_assoc_exists(:reported_condition, &:fever_or_fever_reducer)
                                                  .maximum(:created_at)
    )
  end
end
