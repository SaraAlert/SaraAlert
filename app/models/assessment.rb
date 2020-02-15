class Assessment < ApplicationRecord
  # TODO: There's currently a hard coded symptom list, but those should be configurable
  # TODO: Temperature should be stored with units or strictly using MKS
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
