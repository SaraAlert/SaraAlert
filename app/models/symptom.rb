class Symptom < ApplicationRecord
    def as_json(options = {})
        super(options).merge({
          field_type: type
        })
    end

    def self.symptom_factory(symp)
      if symp['field_type'] == "FloatSymptom" || symp['float_value'] != nil
        return FloatSymptom.create(symp.except(:field_type))
      elsif symp['field_type'] == "BoolSymptom" || symp['bool_value'] != nil
        return BoolSymptom.create(symp.except(:field_type))
      elsif symp['field_type'] == "IntegerSymptom" || symp['int_value'] != nil
        return IntegerSymptom.create(symp.except(:field_type))
      end
    end
end
