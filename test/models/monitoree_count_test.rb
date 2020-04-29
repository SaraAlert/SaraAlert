# frozen_string_literal: true

require 'test_case'

class MonitoreeCountTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create monitoree count' do
    assert create(:monitoree_count)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:monitoree_count, analytic: nil)
    end
  end
end
