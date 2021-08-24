# frozen_string_literal: true

# This migration was created to change manual contact attempt history items from 'Contact Attempt' to 'Manual Contact Attempt' History type
class AddManualContactAttemptHistoryType < ActiveRecord::Migration[6.1]
  def up
    History.where('history_type = ? AND created_by not like ?', 'Contact Attempt', 'Sara Alert System').update_all(history_type: 'Manual Contact Attempt')
  end

  def down
    History.where(history_type: 'Manual Contact Attempt').update_all(history_type: 'Contact Attempt')
  end
end
