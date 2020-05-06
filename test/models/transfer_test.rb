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
