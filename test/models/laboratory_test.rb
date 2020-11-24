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

  # test 'validates report date constraints' do
  #   laboratory = build(:laboratory, report: 30.days.ago)
  #   assert laboratory.valid?

  #   laboratory = build(:laboratory, report: nil)
  #   assert laboratory.valid?

  #   laboratory = build(:laboratory, report: Time.now)
  #   assert laboratory.valid?

  #   laboratory = build(:laboratory, report: 1.day.from_now)
  #   assert_not laboratory.valid?

  #   laboratory = build(:laboratory, report: Date.new(1900, 1, 1))
  #   assert_not laboratory.valid?
  # end

  # test 'validates specimen collection date constraints' do
  #   laboratory = build(:laboratory, specimen_collection: 30.days.ago)
  #   assert laboratory.valid?

  #   laboratory = build(:laboratory, specimen_collection: nil)
  #   assert laboratory.valid?

  #   laboratory = build(:laboratory, specimen_collection: Time.now)
  #   assert laboratory.valid?

  #   laboratory = build(:laboratory, specimen_collection: 1.day.from_now)
  #   assert_not laboratory.valid?

  #   laboratory = build(:laboratory, specimen_collection: Date.new(1900, 1, 1))
  #   assert_not laboratory.valid?
  # end

  test 'update patient linelist' do
    patient = create(:patient)

    # Create laboratory 1 as indeterminate
    laboratory_1 = create(:laboratory, patient: patient, result: 'indeterminate')
    assert_nil patient.latest_positive_lab_at
    assert patient.negative_lab_count.zero?

    # Update assessment 1 to be negative
    laboratory_1.update(result: 'negative')
    assert_nil patient.latest_positive_lab_at
    assert_equal 1, patient.negative_lab_count

    # Update assessment 1 to be positive
    timestamp_1 = 4.days.ago
    laboratory_1.update(result: 'positive', specimen_collection: timestamp_1)
    assert_equal timestamp_1.to_date, patient.latest_positive_lab_at
    assert patient.negative_lab_count.zero?

    # Create laboratory 2 as negative
    timestamp_2 = 2.days.ago
    laboratory_2 = create(:laboratory, patient: patient, result: 'negative', specimen_collection: timestamp_2)
    assert_equal timestamp_1.to_date, patient.latest_positive_lab_at
    assert_equal 1, patient.negative_lab_count

    # Update laboratory 1 back to negative
    laboratory_1.update(result: 'negative')
    assert_nil patient.latest_positive_lab_at
    assert_equal 2, patient.negative_lab_count

    # Destory laboratory 1
    laboratory_1.destroy
    assert_nil patient.latest_positive_lab_at
    assert_equal 1, patient.negative_lab_count

    # Destory laboratory 2
    laboratory_2.destroy!
    assert_nil patient.latest_positive_lab_at
    assert patient.negative_lab_count.zero?
    assert_empty patient.laboratories
  end
end
