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

  def test_full_migration
    # Set up data
    rollback_to_previous_of!(@migration_file)
    # Assert data changed as you would expect going DOWN
    upgrade_to!(@migration_file)
    # Assert data changed as you would expect going UP
  end
end
