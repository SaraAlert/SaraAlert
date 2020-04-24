# frozen_string_literal: true

require 'test_case'

class JurisdictionTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create jurisdiction' do
    assert create(:jurisdiction)
  end
end
