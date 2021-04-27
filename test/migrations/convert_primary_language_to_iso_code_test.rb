# frozen_string_literal: true

require 'migration_test_case'

class ConvertPrimaryLanguageToIsoCodeTest < MigrationTestCase
  require_migration!

  def setup
    super
    # Even if no factories were created, fixtures are probably loaded
    # Remove subjects of this migration to start fresh
    Patient.destroy_all
    History.destroy_all
  end

  def teardown
    # Remove the subjects of the migration before calling super so that
    # the migration back up will work.
    Patient.destroy_all
    History.destroy_all
    super
  end

  def test_migration_known_language
    # Set up data
    patient = create(:patient, primary_language: 'spa', secondary_language: 'spa', legacy_primary_language: 'Espanol', legacy_secondary_language: 'dad span')
    create(:history, patient: patient, history_type: 'System Record Edit', comment: 'Secondary language was listed as dad span which could not be matched')
    rollback_to_previous_of!(@migration_file)
    # Assert data changed as you would expect going DOWN
    patient.reload
    assert_equal('Espanol', patient.primary_language)
    assert_equal('dad span', patient.secondary_language)
    assert_equal(0, patient.histories.length)
    upgrade_to!(@migration_file)
    # Assert data changed as you would expect going UP
    patient.reload
    assert_equal('spa', patient.primary_language)
    assert_equal('spa', patient.secondary_language)
    assert_equal('Espanol', patient.legacy_primary_language)
    assert_equal('dad span', patient.legacy_secondary_language)
    # Only create history items based on TRANSLATION_COMMENTS which does not include 'Espanol'
    assert_equal(1, patient.histories.length)
    assert_includes(patient.histories.first.comment, 'dad span')
  end

  def test_migration_unknown_language
    patient = create(:patient, primary_language: 'eng', legacy_primary_language: 'Klingon')
    create(:history, patient: patient, history_type: 'System Record Edit', comment: 'Primary language was listed as Klingon which could not be matched')
    rollback_to_previous_of!(@migration_file)
    patient.reload
    assert_equal('Klingon', patient.primary_language)
    assert_nil(patient.secondary_language)
    upgrade_to!(@migration_file)
    patient.reload
    # Unknown language gets set to nil
    assert_nil(patient.primary_language)
    assert_equal('Klingon', patient.legacy_primary_language)
    assert_nil(patient.secondary_language)
    # Create a history item that says the language could not be converted
    assert_equal(1, patient.histories.length)
    assert_includes(patient.histories.first.comment, 'Klingon')
  end

  def test_migration_additional_history_items
    patient = create(:patient, primary_language: 'spa', legacy_primary_language: 'dad span')
    create(:history, patient: patient, history_type: 'System Record Edit', comment: 'Primary language was listed as dad span which could not be matched')
    create(:history, patient: patient, history_type: 'System Record Edit', comment: 'Some other system changes')
    create(:history, patient: patient, history_type: 'Comment', comment: 'I have a comment')
    rollback_to_previous_of!(@migration_file)
    patient.reload
    # Did not remove other Comment type history and did not remove other System Record Edit history
    assert_equal(2, patient.histories.length)
    assert_equal('Some other system changes', patient.histories.where(history_type: 'System Record Edit').first.comment)
    upgrade_to!(@migration_file)
    patient.reload
    assert_equal(3, patient.histories.length)
  end
end
