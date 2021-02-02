# frozen_string_literal: true

require 'test_case'

class TransferTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'get lastest transfers scope' do
    # Ensure that one patient does not have two transfers returned when a
    # previous transfer has the same timestamp as another patient's latest transfer
    jur_1 = create(:jurisdiction)
    jur_2 = create(:jurisdiction)
    user = create(:user)
    # :created_at has precision: 6, while latest_transfer_at
    # has no specified precision. It's unclear if this is an issue outside of
    # the test or not - needs further investigation.
    timestamp_1 = (Time.zone.now - 5.days).to_i
    timestamp_2 = (Time.zone.now - 2.days).to_i

    patients = [
      build(:patient),
      build(:patient),
      build(:patient)
    ]
    transfers = [
      Transfer.create!(patient: patients[0], from_jurisdiction: jur_1, to_jurisdiction: jur_2, who: user),
      Transfer.create!(patient: patients[0], from_jurisdiction: jur_2, to_jurisdiction: jur_1, who: user),
      Transfer.create!(patient: patients[1], from_jurisdiction: jur_1, to_jurisdiction: jur_2, who: user),
      Transfer.create!(patient: patients[1], from_jurisdiction: jur_2, to_jurisdiction: jur_1, who: user),
      Transfer.create!(patient: patients[2], from_jurisdiction: jur_2, to_jurisdiction: jur_1, who: user)
    ]
    transfers[0].update(created_at: Time.zone.at(timestamp_1))
    transfers[1].update(created_at: Time.zone.at(timestamp_2))
    transfers[2].update(created_at: Time.zone.at(timestamp_1))
    transfers[3].update(created_at: Time.zone.at(timestamp_2))
    transfers[4].update(created_at: Time.zone.at(timestamp_1))
    patients[0].update(latest_transfer_at: Time.zone.at(timestamp_2))
    patients[1].update(latest_transfer_at: Time.zone.at(timestamp_2))
    patients[2].update(latest_transfer_at: Time.zone.at(timestamp_1))
    transfers.each(&:reload)
    patients.each(&:reload)

    assert_equal 3, Transfer.latest_transfers(patients).size
    assert_includes Transfer.latest_transfers(patients).pluck(:id), transfers[1].id
    assert_includes Transfer.latest_transfers(patients).pluck(:id), transfers[3].id
    assert_includes Transfer.latest_transfers(patients).pluck(:id), transfers[4].id

    patient_without_transfer = build(:patient)

    assert_equal 3, Transfer.latest_transfers(patients + [patient_without_transfer]).size
    assert_includes Transfer.latest_transfers(patients).pluck(:id), transfers[1].id
    assert_includes Transfer.latest_transfers(patients).pluck(:id), transfers[3].id
    assert_includes Transfer.latest_transfers(patients).pluck(:id), transfers[4].id
  end

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
    jur_1 = create(:jurisdiction)
    patient = create(:patient, jurisdiction: jur_1)

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
