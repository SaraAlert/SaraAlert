# frozen_string_literal: true

require 'test_case'

class SidekiqTest < ActiveSupport::TestCase
  test 'sidekiq returns a length 24 hex string' do
    assert ConsumeAssessmentsJob.perform_async("{'key': true}").match?(/[a-f0-9]{24}/)
  end
end
