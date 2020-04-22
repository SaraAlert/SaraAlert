# frozen_string_literal: true

require 'test_helper'

class HistoryTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create history' do
    assert create(:history, history_type: 'Report Created')
    assert create(:history, history_type: 'Report Updated')
    assert create(:history, history_type: 'Comment')
    assert create(:history, history_type: 'Enrollment')
    assert create(:history, history_type: 'Monitoring Change')
    assert create(:history, history_type: 'Reports Reviewed')
    assert create(:history, history_type: 'Report Reviewed')
    assert create(:history, history_type: 'Report Reminder')
    assert create(:history, history_type: 'Report Note')
    assert create(:history, history_type: 'Comment', comment: 'v' * 2000)
    assert create(:history, history_type: 'Comment', created_by: 'v' * 200)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:history, history_type: 'Invalid')
      # Text column type
      create(:history, history_type: 'Comment', comment: 'v' * 2001)
      # String colomn type
      create(:history, history_type: 'Comment', created_by: 'v' * 201)
    end
  end
end
