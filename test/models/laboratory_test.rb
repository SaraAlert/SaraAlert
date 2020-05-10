# frozen_string_literal: true

require 'test_case'

class LaboratoryTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create laboratory' do
    assert create(:laboratory)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:laboratory, patient: nil)
    end
  end
end
