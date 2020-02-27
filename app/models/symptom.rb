class Symptom < ApplicationRecord
    def as_json(options = {})
        super(options).merge({
          field_type: type
        })
    end
end
