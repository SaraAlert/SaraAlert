class Symptom < ApplicationRecord
    columns.each do |column|
      case column.type
      when :text
        validates column.name.to_sym, length: { maximum: 2000 }
      when :string
        validates column.name.to_sym, length: { maximum: 200 }
      end
    end
    def as_json(options = {})
        super(options).merge({
          type: type
        })
    end

end
