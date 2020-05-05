# frozen_string_literal: true

require 'test_case'

class AnalyticTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create analytic' do
    assert create(:analytic)
  end
end
