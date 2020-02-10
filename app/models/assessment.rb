class Assessment < ApplicationRecord
  # TODO: We assume that we can rely on the frontend for "context-aware" validation
  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end
  belongs_to :patient
end
