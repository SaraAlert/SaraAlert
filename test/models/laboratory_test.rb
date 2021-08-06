# frozen_string_literal: true

require 'test_case'

# IMPORTANT NOTE ON CHANGES TO Time.now CALLS IN THIS FILE
# Updated Time.now to Time.now.getlocal for Rails/TimeZone because Time.now defaulted to a zone. In this case it was the developer machine or CI/CD server zone.
class LaboratoryTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create laboratory' do
    assert create(:laboratory)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:laboratory, patient: nil)
    end
  end

  test 'validates report date constraints' do
    laboratory = build(:laboratory, report: 30.days.ago)
    assert laboratory.valid?(:api)
    assert laboratory.valid?(:import)

    laboratory = build(:laboratory, report: nil)
    assert laboratory.valid?(:api)
    assert laboratory.valid?(:import)

    laboratory = build(:laboratory, report: Time.now.getlocal)
    assert laboratory.valid?(:api)
    assert laboratory.valid?(:import)

    # Date cannot be in the future
    laboratory = build(:laboratory, report: 1.day.from_now)
    assert_not laboratory.valid?(:api)
    assert_not laboratory.valid?(:import)

    # Date cannot be before start year
    laboratory = build(:laboratory, report: Date.new(1900, 1, 1))
    assert_not laboratory.valid?(:api)
    assert_not laboratory.valid?(:import)
  end

  test 'validates specimen collection date constraints' do
    laboratory = build(:laboratory, specimen_collection: 30.days.ago)
    assert laboratory.valid?(:api)
    assert laboratory.valid?(:import)

    laboratory = build(:laboratory, specimen_collection: nil)
    assert laboratory.valid?(:api)
    assert laboratory.valid?(:import)

    laboratory = build(:laboratory, specimen_collection: Time.now.getlocal)
    assert laboratory.valid?(:api)
    assert laboratory.valid?(:import)

    laboratory = build(:laboratory, specimen_collection: 1.day.from_now)
    assert_not laboratory.valid?(:api)
    assert_not laboratory.valid?(:import)

    laboratory = build(:laboratory, specimen_collection: Date.new(1900, 1, 1))
    assert_not laboratory.valid?(:api)
    assert_not laboratory.valid?(:import)

    # Ensure specimen collection date is before report date
    laboratory = build(:laboratory, specimen_collection: 1.day.ago, report: 2.days.ago)
    assert_not laboratory.valid?(:api)
    assert_not laboratory.valid?(:import)

    laboratory = build(:laboratory, specimen_collection: 2.days.ago, report: 1.day.ago)
    assert laboratory.valid?(:api)
    assert laboratory.valid?(:import)
  end

  test 'update patient updated_at upon laboratory create, update, and delete' do
    patient = create(:patient)

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    laboratory = create(:laboratory, patient: patient)
    assert_in_delta patient.updated_at, Time.now.utc, 1

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    laboratory.update(result: 'negative')
    assert_in_delta patient.updated_at, Time.now.utc, 1

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    laboratory.destroy
    assert_in_delta patient.updated_at, Time.now.utc, 1
  end

  test 'update patient linelist' do
    patient = create(:patient)

    # Create laboratory 1 as indeterminate
    laboratory_1 = create(:laboratory, patient: patient, result: 'indeterminate')
    assert_nil patient.first_positive_lab_at
    assert patient.negative_lab_count.zero?

    # Update assessment 1 to be negative
    laboratory_1.update(result: 'negative')
    assert_nil patient.first_positive_lab_at
    assert_equal 1, patient.negative_lab_count

    # Update assessment 1 to be positive
    timestamp_1 = 4.days.ago
    laboratory_1.update(result: 'positive', specimen_collection: timestamp_1)
    assert_equal timestamp_1.to_date, patient.first_positive_lab_at
    assert patient.negative_lab_count.zero?

    # Create laboratory 2 as negative
    timestamp_2 = 2.days.ago
    laboratory_2 = create(:laboratory, patient: patient, result: 'negative', specimen_collection: timestamp_2)
    assert_equal timestamp_1.to_date, patient.first_positive_lab_at
    assert_equal 1, patient.negative_lab_count

    # Update laboratory 1 back to negative
    laboratory_1.update(result: 'negative')
    assert_nil patient.first_positive_lab_at
    assert_equal 2, patient.negative_lab_count

    # Destory laboratory 1
    laboratory_1.destroy
    assert_nil patient.first_positive_lab_at
    assert_equal 1, patient.negative_lab_count

    # Destory laboratory 2
    laboratory_2.destroy!
    assert_nil patient.first_positive_lab_at
    assert patient.negative_lab_count.zero?
    assert_empty patient.laboratories
  end

  test 'validates result inclusion' do
    lab = create(:laboratory)

    lab.result = 'positive'
    assert lab.valid?
    lab.result = 'negative'
    assert lab.valid?
    lab.result = 'indeterminate'
    assert lab.valid?
    lab.result = 'other'
    assert lab.valid?
    lab.result = ''
    assert lab.valid?
    lab.result = nil
    assert lab.valid?

    lab.result = 'foo'
    assert_not lab.valid?
  end

  test 'validates lab_type inclusion in api and import context' do
    lab = create(:laboratory)

    lab.lab_type = 'PCR'
    assert lab.valid?(:api)
    assert lab.valid?(:import)
    lab.lab_type = 'Antigen'
    assert lab.valid?(:api)
    assert lab.valid?(:import)
    lab.lab_type = 'Total Antibody'
    assert lab.valid?(:api)
    assert lab.valid?(:import)
    lab.lab_type = 'IgG Antibody'
    assert lab.valid?(:api)
    assert lab.valid?(:import)
    lab.lab_type = 'IgM Antibody'
    assert lab.valid?(:api)
    assert lab.valid?(:import)
    lab.lab_type = 'IgA Antibody'
    assert lab.valid?(:api)
    assert lab.valid?(:import)
    lab.lab_type = 'Other'
    assert lab.valid?(:api)
    assert lab.valid?(:import)
    lab.lab_type = ''
    assert lab.valid?(:api)
    assert lab.valid?(:import)
    lab.lab_type = nil
    assert lab.valid?(:api)
    assert lab.valid?(:import)

    lab.lab_type = 'foo'
    assert_not lab.valid?(:api)
    assert_not lab.valid?(:import)
    assert lab.valid?
  end

  test 'validates specimen_collection is a valid date' do
    lab = create(:laboratory)

    lab.specimen_collection = Time.now.getlocal - 1.day
    assert lab.valid?(:api)
    assert lab.valid?(:import)

    lab.specimen_collection = ''
    assert lab.valid?(:api)
    assert lab.valid?(:import)

    lab.specimen_collection = nil
    assert lab.valid?(:api)
    assert lab.valid?(:import)

    lab.specimen_collection = '01-15-2000'
    assert_not lab.valid?(:api)
    assert_not lab.valid?(:import)

    lab.specimen_collection = '2000-13-13'
    assert_not lab.valid?(:api)
    assert_not lab.valid?(:import)
    assert lab.valid?

    lab.specimen_collection = '2021-02-02 2021-01-01'
    assert_not lab.valid?(:import)

    lab.specimen_collection = 'typo2021-01-01'
    assert_not lab.valid?(:api)
    assert_not lab.valid?(:import)

    lab.specimen_collection = '2021-01-01typo'
    assert_not lab.valid?(:api)
    assert_not lab.valid?(:import)

    lab.specimen_collection = 20_210_101
    assert_not lab.valid?(:import)
    assert_not lab.valid?(:api)
    assert_equal 'is not a valid date, please use the \'YYYY-MM-DD\' format', lab.errors[:specimen_collection][0]

    lab.specimen_collection = 20_210_001
    assert_not lab.valid?(:import)
    assert_not lab.valid?(:api)
    assert_equal 'is not a valid date, please use the \'YYYY-MM-DD\' format', lab.errors[:specimen_collection][0]

    lab.specimen_collection = 20_210_101.001
    assert_not lab.valid?(:import)
    assert_not lab.valid?(:api)
    assert_equal 'is not a valid date, please use the \'YYYY-MM-DD\' format', lab.errors[:specimen_collection][0]
  end

  test 'validates report is a valid date' do
    lab = create(:laboratory)

    lab.report = Time.now.getlocal - 1.day
    assert lab.valid?(:api)
    assert lab.valid?(:import)

    lab.report = ''
    assert lab.valid?(:api)
    assert lab.valid?(:import)

    lab.report = nil
    assert lab.valid?(:api)
    assert lab.valid?(:import)

    lab.report = '01-15-2000'
    assert_not lab.valid?(:api)
    assert_not lab.valid?(:import)
    assert lab.valid?

    lab.report = '2000-13-13'
    assert_not lab.valid?(:api)
    assert_not lab.valid?(:import)
    assert lab.valid?

    lab.report = '2021-02-02 2021-01-01'
    assert_not lab.valid?(:import)

    lab.report = 'typo2021-01-01'
    assert_not lab.valid?(:api)
    assert_not lab.valid?(:import)

    lab.report = '2021-01-01typo'
    assert_not lab.valid?(:api)
    assert_not lab.valid?(:import)

    lab.report = 20_210_101
    assert_not lab.valid?(:import)
    assert_not lab.valid?(:api)
    assert_equal 'is not a valid date, please use the \'YYYY-MM-DD\' format', lab.errors[:report][0]

    lab.report = 20_210_001
    assert_not lab.valid?(:import)
    assert_not lab.valid?(:api)
    assert_equal 'is not a valid date, please use the \'YYYY-MM-DD\' format', lab.errors[:report][0]

    lab.report = 20_210_101.001
    assert_not lab.valid?(:import)
    assert_not lab.valid?(:api)
    assert_equal 'is not a valid date, please use the \'YYYY-MM-DD\' format', lab.errors[:report][0]
  end
end
