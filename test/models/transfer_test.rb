# frozen_string_literal: true

require 'test_case'

class TransferTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create transfer' do
    assert(create(:transfer))

    exception = assert_raises(ActiveRecord::RecordInvalid) do
      transfer = build(:transfer)
      transfer.patient = nil
      transfer.save!
    end
    assert_includes(exception.message, 'Patient')

    exception = assert_raises(ActiveRecord::RecordInvalid) do
      transfer = build(:transfer)
      transfer.to_jurisdiction = nil
      transfer.save!
    end
    assert_includes(exception.message, 'To jurisdiction')

    exception = assert_raises(ActiveRecord::RecordInvalid) do
      transfer = build(:transfer)
      transfer.from_jurisdiction = nil
      transfer.save!
    end
    assert_includes(exception.message, 'From jurisdiction')

    exception = assert_raises(ActiveRecord::RecordInvalid) do
      transfer = build(:transfer)
      transfer.who = nil
      transfer.save!
    end
    assert_includes(exception.message, 'Who')
  end

  test 'update patient linelist' do
    # Create new patient and verify default linelist values
    jur_1 = create(:jurisdiction)
    patient = create(:patient, jurisdiction: jur_1)
    assert_nil patient.latest_transfer_at
    assert_nil patient.latest_transfer_from
    assert_empty patient.transfers

    # Create transfer 1
    timestamp_1 = 5.days.ago
    jur_2 = create(:jurisdiction)
    user = create(:user)
    transfer_1 = Transfer.create!(patient: patient, created_at: timestamp_1, from_jurisdiction: jur_2, to_jurisdiction: jur_1, who: user)
    assert_in_delta timestamp_1, patient.latest_transfer_at, 1
    assert_equal jur_2.id, patient.latest_transfer_from

    # Create transfer 2
    timestamp_2 = 7.days.ago
    jur_3 = create(:jurisdiction)
    transfer_2 = Transfer.create!(patient: patient, created_at: timestamp_2, from_jurisdiction: jur_3, to_jurisdiction: jur_2, who: user)
    assert_in_delta timestamp_1, patient.latest_transfer_at, 1
    assert_equal jur_2.id, patient.latest_transfer_from

    # Update transfer 2 created at
    timestamp_2 = 4.days.ago
    transfer_2.update!(created_at: timestamp_2)
    assert_in_delta timestamp_2, patient.latest_transfer_at, 1
    assert_equal jur_3.id, patient.latest_transfer_from

    # Update transfer 2 created at
    timestamp_2 = 4.days.ago
    transfer_2.update(created_at: timestamp_2)
    assert_in_delta timestamp_2, patient.latest_transfer_at, 1
    assert_equal jur_3.id, patient.latest_transfer_from

    # Update transfer 2 from jurisdiction
    jur_4 = create(:jurisdiction)
    transfer_2.update!(from_jurisdiction: jur_4)
    assert_in_delta timestamp_2, patient.latest_transfer_at, 1
    assert_equal jur_4.id, patient.latest_transfer_from

    # Destroy transfer 2
    transfer_2.destroy
    assert_in_delta timestamp_1, patient.latest_transfer_at, 1
    assert_equal jur_2.id, patient.latest_transfer_from

    # Destroy transfer 2
    transfer_1.destroy
    assert_nil patient.latest_transfer_at
    assert_nil patient.latest_transfer_from
    assert_empty patient.transfers
  end

  test 'from path' do
    from_jurisdiction = create(:jurisdiction)
    transfer = build(:transfer)
    transfer.from_jurisdiction = from_jurisdiction
    transfer.save!
    assert_equal(transfer.from_path, from_jurisdiction.jurisdiction_path_string)
  end

  test 'to path' do
    to_jurisdiction = create(:jurisdiction)
    transfer = create(:transfer, to_jurisdiction: to_jurisdiction)
    assert_equal(transfer.to_path, to_jurisdiction.jurisdiction_path_string)
  end

  test 'with incoming jurisdiction id' do
    to_jurisdiction = create(:jurisdiction)

    assert_difference("Transfer.with_incoming_jurisdiction_id(#{to_jurisdiction.id}).size", 1) do
      create(:transfer, to_jurisdiction: to_jurisdiction)
    end

    assert_no_difference("Transfer.with_incoming_jurisdiction_id(#{to_jurisdiction.id}).size") do
      create(:transfer)
    end
  end

  test 'with outgoing jurisdiction id' do
    from_jurisdiction = create(:jurisdiction)

    assert_difference("Transfer.with_outgoing_jurisdiction_id(#{from_jurisdiction.id}).size", 1) do
      transfer = build(:transfer)
      transfer.from_jurisdiction = from_jurisdiction
      transfer.save!
    end

    assert_no_difference("Transfer.with_outgoing_jurisdiction_id(#{from_jurisdiction.id}).size") do
      create(:transfer)
    end
  end

  test 'transfer in time frame' do
    assert_no_difference("Transfer.in_time_frame('Invalid').size") do
      create(:transfer)
    end
    assert_equal(0, Transfer.in_time_frame('Invalid').size)

    assert_difference("Transfer.in_time_frame('Last 24 Hours').size", 1) do
      create(:transfer)
    end

    assert_no_difference("Transfer.in_time_frame('Last 24 Hours').size") do
      create(:transfer).update(created_at: 25.hours.ago)
    end

    assert_difference("Transfer.in_time_frame('Last 14 Days').size", 1) do
      create(:transfer).update(created_at: 1.day.ago)
    end

    # Specific case where we don't want the number to change throughout the day
    assert_no_difference("Transfer.in_time_frame('Last 14 Days').size") do
      create(:transfer)
    end

    assert_no_difference("Transfer.in_time_frame('Last 14 Days').size") do
      create(:transfer).update(created_at: 15.days.ago)
    end

    assert_difference("Transfer.in_time_frame('Total').size", 1) do
      create(:transfer).update(created_at: 15.days.ago)
    end
  end
end
