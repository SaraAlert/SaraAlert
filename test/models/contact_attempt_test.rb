# frozen_string_literal: true

require 'test_case'

class ContactAttemptTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'update patient updated_at upon contact_attempt create, update, and delete' do
    patient = create(:patient)

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    contact_attempt = create(:contact_attempt, patient: patient)
    assert_in_delta patient.updated_at, Time.now.utc, 1

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    contact_attempt.update(successful: true)
    assert_in_delta patient.updated_at, Time.now.utc, 1

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    contact_attempt.destroy
    assert_in_delta patient.updated_at, Time.now.utc, 1
  end
end
