# frozen_string_literal: true

require 'test_case'

class DestroyDownloadsJobTest < ActiveSupport::TestCase
  test 'download exists' do
    assert(DestroyDownloadsJob.perform_now(create(:download).id))
  end

  # When performing another export of the same type, all existing downloads of that type
  # will be deleted before the job runs. It should not raise in this case.
  test 'download does not exist' do
    assert_nothing_raised do
      DestroyDownloadsJob.perform_now(0)
    end
  end
end
