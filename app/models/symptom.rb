class Symptom < ApplicationRecord
    def as_json(options = {})
        super(options).merge({
          field_type: type
        })
    end

    def self.symptom_factory(symp)
      if symp['field_type'] == "FloatSymptom"
        return FloatSymptom.create(symp.except(:field_type))
      elsif symp['field_type'] == "BoolSymptom"
        return BoolSymptom.create(symp.except(:field_type))
      elsif symp['field_type'] == "IntegerSymptom"
        return IntegerSymptom.create(symp.except(:field_type))
      end
    end
end
