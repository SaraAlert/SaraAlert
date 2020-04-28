# frozen_string_literal: true

require 'test_case'

class MonitoreeSnapshotTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create monitoree snapshot' do
    assert create(:monitoree_snapshot)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:monitoree_snapshot, analytic: nil)
    end
  end
end
