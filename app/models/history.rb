require 'action_view'
require 'action_view/helpers'

class History < ApplicationRecord
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
