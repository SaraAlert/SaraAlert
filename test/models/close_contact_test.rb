# frozen_string_literal: true

require 'test_case'

class CloseContactTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'update patient updated_at upon close_contact create, update, and delete' do
    patient = create(:patient)

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    close_contact = create(:close_contact, patient: patient)
    assert_in_delta patient.updated_at, DateTime.now, 1

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    close_contact.update(contact_attempts: 2)
    assert_in_delta patient.updated_at, DateTime.now, 1

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    close_contact.destroy
    assert_in_delta patient.updated_at, DateTime.now, 1
  end
end
