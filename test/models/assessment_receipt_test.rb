# frozen_string_literal: true

require 'test_case'

class AssessmentReceiptTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create assessment receipt' do
    assert create(:assessment_receipt)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      create(:assessment_receipt, submission_token: nil)
    end
    assert_includes(error.message, 'Submission token')
  end
end
